# frozen_string_literal: true

require("test_helper")

class ScriptTest < UnitTestCase
  DATABASE_CONFIG = YAML.safe_load(IO.
    read("#{::Rails.root}/config/database.yml"))["test"]

  def script_file(cmd)
    "#{::Rails.root}/script/#{cmd}"
  end

  def local_root
    "#{::Rails.root}/public/test_images"
  end

  def remote_root
    "#{::Rails.root}/public/test_server"
  end

  # Stable autogenerated IDs of some image fixtures
  # We cannot reference the db in a tests before running a script
  # for the reason stated in test_retransfer_image below.
  # So get these IDs without refering to the db.
  # rubocop:disable Style/NumericLiterals
  def in_situ_id
    688136226
  end

  def turned_over_id
    1062212448
  end

  def commercial_id
    566571202
  end

  def disconnected_id
    839420571
  end
  # rubocop:enable Style/NumericLiterals

  def setup
    FileUtils.rm_rf(local_root)
    FileUtils.rm_rf("#{remote_root}1")
    FileUtils.rm_rf("#{remote_root}2")
    %w[thumb 320 640 960 1280 orig].each do |subdir|
      FileUtils.mkpath("#{local_root}/#{subdir}")
      FileUtils.mkpath("#{remote_root}1/#{subdir}")
      FileUtils.mkpath("#{remote_root}2/#{subdir}")
    end
    super
  end

  def teardown
    # Need to reset any possible changes to database scripts might make because
    # they are external to the ActiveRecord test transanction which normally
    # rolls back any changes which occur inside a given test.
    cmd = "UPDATE images
           SET width=1000, height=1000, transferred=false
           WHERE id=#{in_situ_id}"
    system("mysql --defaults-extra-file=#{mysql_config_file} -e '#{cmd}'")
    FileUtils.rm_rf(local_root)
    FileUtils.rm_rf("#{remote_root}1")
    FileUtils.rm_rf("#{remote_root}2")
    clear_image_transferred_state_externally(in_situ_id)
    clear_image_transferred_state_externally(turned_over_id)
    super
  end

  def clear_image_transferred_state_externally(id)
    system("mysql --defaults-extra-file=#{mysql_config_file} -e " \
           "'update images set transferred=false where id = #{id}'")
  end

  def get_image_transferred_state_externally(id)
    result = `mysql --defaults-extra-file=#{mysql_config_file} -e ' \
             '"select transferred from images where id = #{id}"`
    result.split("\n").last.strip == "1"
  end

  def mysql_config_file
    Rails.root.join("config", "mysql-#{Rails.env}.cnf")
  end

  ##############################################################################

  test "fixture_id_defs" do
    assert_equal(images(:in_situ_image).id, in_situ_id,
                 "in_situ_id defined incorrectly")
    assert_equal(images(:turned_over_image).id, turned_over_id,
                 "turned_over_id defined incorrectly")
    assert_equal(images(:commercial_inquiry_image).id, commercial_id,
                 "commercial_id defined incorrectly")
    assert_equal(images(:disconnected_coprinus_comatus_image).id,
                 disconnected_id,
                 "disconnected_id defined incorrectly")
  end

  test "process_image" do
    script = script_file("process_image")
    tempfile = Tempfile.new("test").path
    original_image = "#{::Rails.root}/test/images/pleopsidium.tiff"
    FileUtils.cp(original_image, "#{local_root}/orig/#{in_situ_id}.tiff")
    errors, status = Open3.capture2e(script, in_situ_id.to_s, "tiff", "1", "2")
    assert(status && errors.blank?,
           "Something went wrong with #{script}:\n#{errors}")
    File.open(tempfile, "w") do |file|
      file.puts("#{local_root}/orig//#{in_situ_id}.jpg")
      file.puts("#{local_root}/1280//#{in_situ_id}.jpg")
      file.puts("#{local_root}/960//#{in_situ_id}.jpg")
      file.puts("#{local_root}/640//#{in_situ_id}.jpg")
      file.puts("#{local_root}/320//#{in_situ_id}.jpg")
      file.puts("#{local_root}/thumb//#{in_situ_id}.jpg")
    end
    output, _status = Open3.capture2(script_file("jpegsize"), "-f", tempfile)
    sizes = output.each_line.map do |line|
      line[local_root.length + 1..-1].chomp
    end
    assert_equal("orig//#{in_situ_id}.jpg: 2560 1920", sizes[0],
                 "full-size image is wrong size")
    assert_equal("1280//#{in_situ_id}.jpg: 1280 960", sizes[1],
                 "huge-size image is wrong size")
    assert_equal("960//#{in_situ_id}.jpg: 960 720", sizes[2],
                 "large-size image is wrong size")
    assert_equal("640//#{in_situ_id}.jpg: 640 480", sizes[3],
                 "medium-size image is wrong size")
    assert_equal("320//#{in_situ_id}.jpg: 320 240", sizes[4],
                 "small-size image is wrong size")
    assert_equal("thumb//#{in_situ_id}.jpg: 160 120", sizes[5],
                 "thumbnail image is wrong size")

    img = images(:in_situ_image)

    assert_equal(2560, img.width)
    assert_equal(1920, img.height)
    assert_equal(true, img.transferred)

    ["thumb/#{in_situ_id}.jpg", "320/#{in_situ_id}.jpg",
     "640/#{in_situ_id}.jpg", "960/#{in_situ_id}.jpg", "1280/#{in_situ_id}.jpg",
     "orig/#{in_situ_id}.jpg", "orig/#{in_situ_id}.tiff"].each do |file|
      file1 = "#{local_root}/#{file}"
      file2 = "#{remote_root}1/#{file}"
      assert_equal(File.size(file1), File.size(file2),
                   "Failed to transfer #{file} to server 1, size is wrong.")
    end
    ["thumb/#{in_situ_id}.jpg", "320/#{in_situ_id}.jpg",
     "640/#{in_situ_id}.jpg"].each do |file|
      file1 = "#{local_root}/#{file}"
      file2 = "#{remote_root}2/#{file}"
      assert_equal(File.size(file1), File.size(file2),
                   "Failed to transfer #{file} to server 2, size is wrong.")
    end
    ["960/#{in_situ_id}.jpg", "1280/#{in_situ_id}.jpg",
     "orig/#{in_situ_id}.jpg", "orig/#{in_situ_id}.tiff"].each do |file|
      file2 = "#{remote_root}2/#{file}"
      assert_not(File.exist?(file2),
                 "Shouldn't have transferred #{file} to server 2.")
    end
  end

  test "retransfer_images" do
    # In unit tests, ActiveRecord wraps all work on the database in a
    # transaction.  Soon as you look at the database it becomes immune to
    # external changes for the rest of the test.  In this test we want to check
    # whether the script is correctly setting the transferred flag in two
    # images.  If we avoid ActiveRecord's transaction wrapper, we can test this
    # correctly.  However, then it leaves the database in a condition different
    # than it started, and that's also bad.  (Breaks other tests if they happen
    # after this one.)  So we need to avoid the transaction wrapper throughout
    # the whole test, and ensure that it resets the transferred flags
    # externally at the end.

    script = script_file("retransfer_images")
    tempfile = Tempfile.new("test").path

    File.open("#{local_root}/orig/#{in_situ_id}.tiff", "w") do |f|
      f.write("A")
    end
    File.open("#{local_root}/orig/#{in_situ_id}.jpg", "w") do |f|
      f.write("B")
    end
    File.open("#{local_root}/1280/#{in_situ_id}.jpg", "w") do |f|
      f.write("C")
    end
    File.open("#{local_root}/960/#{in_situ_id}.jpg", "w") do |f|
      f.write("D")
    end
    File.open("#{local_root}/640/#{in_situ_id}.jpg", "w") do |f|
      f.write("E")
    end
    File.open("#{local_root}/320/#{in_situ_id}.jpg", "w") do |f|
      f.write("F")
    end
    File.open("#{local_root}/thumb/#{in_situ_id}.jpg", "w") do |f|
      f.write("G")
    end
    File.open("#{local_root}/960/#{turned_over_id}.jpg", "w") do |f|
      f.write("H")
    end
    File.open("#{local_root}/640/#{turned_over_id}.jpg", "w") do |f|
      f.write("I")
    end
    File.open("#{local_root}/320/#{turned_over_id}.jpg", "w") do |f|
      f.write("J")
    end
    File.open("#{local_root}/thumb/#{turned_over_id}.jpg", "w") do |f|
      f.write("K")
    end
    cmd = "#{script} 2>&1 > #{tempfile}"
    status = system(cmd)
    errors = File.read(tempfile)
    assert(status && errors.blank?,
           "Something went wrong with #{script}:\n#{errors}")
    assert_true(get_image_transferred_state_externally(in_situ_id))
    assert_true(get_image_transferred_state_externally(turned_over_id))

    assert_equal("A", File.read("#{remote_root}1/orig/#{in_situ_id}.tiff"),
                 "orig/#{in_situ_id}.tiff wrong for server 1")
    assert_equal("B", File.read("#{remote_root}1/orig/#{in_situ_id}.jpg"),
                 "orig/#{in_situ_id}.jpg wrong for server 1")
    assert_equal("C", File.read("#{remote_root}1/1280/#{in_situ_id}.jpg"),
                 "1280/#{in_situ_id}.jpg wrong for server 1")
    assert_equal("D", File.read("#{remote_root}1/960/#{in_situ_id}.jpg"),
                 "960/#{in_situ_id}.jpg wrong for server 1")
    assert_equal("E", File.read("#{remote_root}1/640/#{in_situ_id}.jpg"),
                 "640/#{in_situ_id}.jpg wrong for server 1")
    assert_equal("F", File.read("#{remote_root}1/320/#{in_situ_id}.jpg"),
                 "320/#{in_situ_id}.jpg wrong for server 1")
    assert_equal("G", File.read("#{remote_root}1/thumb/#{in_situ_id}.jpg"),
                 "thumb/#{in_situ_id}.jpg wrong for server 1")
    assert_equal("H", File.read("#{remote_root}1/960/#{turned_over_id}.jpg"),
                 "960/#{turned_over_id}.jpg wrong for server 1")
    assert_equal("I", File.read("#{remote_root}1/640/#{turned_over_id}.jpg"),
                 "640/#{turned_over_id}.jpg wrong for server 1")
    assert_equal("J", File.read("#{remote_root}1/320/#{turned_over_id}.jpg"),
                 "320/#{turned_over_id}.jpg wrong for server 1")
    assert_equal("K", File.read("#{remote_root}1/thumb/#{turned_over_id}.jpg"),
                 "thumb/#{turned_over_id}.jpg wrong for server 1")
    assert_equal("E", File.read("#{remote_root}2/640/#{in_situ_id}.jpg"),
                 "640/#{in_situ_id}.jpg wrong for server 2")
    assert_equal("F", File.read("#{remote_root}2/320/#{in_situ_id}.jpg"),
                 "320/#{in_situ_id}.jpg wrong for server 2")
    assert_equal("G", File.read("#{remote_root}2/thumb/#{in_situ_id}.jpg"),
                 "thumb/#{in_situ_id}.jpg wrong for server 2")
    assert_equal("I", File.read("#{remote_root}2/640/#{turned_over_id}.jpg"),
                 "640/#{turned_over_id}.jpg wrong for server 2")
    assert_equal("J", File.read("#{remote_root}2/320/#{turned_over_id}.jpg"),
                 "320/#{turned_over_id}.jpg wrong for server 2")
    assert_equal("K", File.read("#{remote_root}2/thumb/#{turned_over_id}.jpg"),
                 "thumb/#{turned_over_id}.jpg wrong for server 2")

    assert_not(File.exist?("#{remote_root}2/orig/#{in_situ_id}.tiff"),
               "orig/#{in_situ_id}.jpg shouldnt be on server 2")
    assert_not(File.exist?("#{remote_root}2/orig/#{in_situ_id}.jpg"),
               "orig/#{in_situ_id}.jpg shouldnt be on server 2")
    assert_not(File.exist?("#{remote_root}2/1280/#{in_situ_id}.jpg"),
               "1280/#{in_situ_id}.jpg shouldnt be on server 2")
    assert_not(File.exist?("#{remote_root}2/960/#{in_situ_id}.jpg"),
               "960/#{in_situ_id}.jpg shouldnt be on server 2")
    assert_not(File.exist?("#{remote_root}2/960/#{turned_over_id}.jpg"),
               "960/#{turned_over_id}.jpg shouldnt be on server 2")
  end

  test "rotate_image" do
    script = script_file("rotate_image")
    tempfile = Tempfile.new("test").path
    test_image = "#{::Rails.root}/test/images/sticky.jpg"
    FileUtils.cp(test_image, "#{remote_root}1/orig/#{in_situ_id}.jpg")
    cmd = "#{script} #{in_situ_id} +90 2>&1 > #{tempfile}"
    status = system(cmd)
    errors = File.read(tempfile)

    assert(status && errors.blank?,
           "Something went wrong with #{script}:\n#{errors}")
    assert(File.exist?("#{local_root}/orig/#{in_situ_id}.jpg"))
    assert(File.exist?("#{local_root}/thumb/#{in_situ_id}.jpg"))
    assert(File.exist?("#{remote_root}1/orig/#{in_situ_id}.jpg"))
    assert(File.exist?("#{remote_root}1/thumb/#{in_situ_id}.jpg"))
    assert_not(File.exist?("#{remote_root}2/orig/#{in_situ_id}.jpg"))
    assert(File.exist?("#{remote_root}2/thumb/#{in_situ_id}.jpg"))

    img = images(:in_situ_image)
    assert_equal(500, img.width)
    assert_equal(407, img.height)
    assert_equal(true, img.transferred)
  end

  test "verify_images" do
    script = script_file("verify_images")
    tempfile = Tempfile.new("test").path
    File.open("#{local_root}/orig/#{turned_over_id}.tiff", "w") do |f|
      f.write("A")
    end
    File.open("#{local_root}/orig/#{turned_over_id}.jpg", "w") do |f|
      f.write("AB")
    end
    File.open("#{local_root}/960/#{turned_over_id}.jpg", "w") do |f|
      f.write("ABC")
    end
    File.open("#{local_root}/640/#{turned_over_id}.jpg", "w") do |f|
      f.write("ABCD")
    end
    File.open("#{local_root}/320/#{turned_over_id}.jpg", "w") do |f|
      f.write("ABCDE")
    end
    File.open("#{local_root}/960/#{commercial_id}.jpg", "w") do |f|
      f.write("ABCDEF")
    end
    File.open("#{local_root}/640/#{commercial_id}.jpg", "w") do |f|
      f.write("ABCDEFG")
    end
    File.open("#{local_root}/320/#{commercial_id}.jpg", "w") do |f|
      f.write("ABCDEFGH")
    end
    File.open("#{local_root}/960/#{disconnected_id}.jpg", "w") do |f|
      f.write("ABCDEFGHI")
    end
    File.open("#{local_root}/640/#{disconnected_id}.jpg", "w") do |f|
      f.write("ABCDEFGHIJ")
    end
    File.open("#{local_root}/320/#{disconnected_id}.jpg", "w") do |f|
      f.write("ABCDEFGHIJK")
    end
    File.open("#{remote_root}1/960/#{in_situ_id}.jpg", "w") do |f|
      f.write("correct")
    end
    File.open("#{remote_root}1/640/#{in_situ_id}.jpg", "w") do |f|
      f.write("correct")
    end
    File.open("#{remote_root}1/320/#{in_situ_id}.jpg", "w") do |f|
      f.write("correct")
    end
    File.open("#{remote_root}1/960/#{turned_over_id}.jpg", "w") do |f|
      f.write("ABC")
    end
    File.open("#{remote_root}1/640/#{turned_over_id}.jpg", "w") do |f|
      f.write("ABCD")
    end
    File.open("#{remote_root}1/320/#{turned_over_id}.jpg", "w") do |f|
      f.write("ABCDE")
    end
    File.open("#{remote_root}1/960/#{commercial_id}.jpg", "w") do |f|
      f.write("ABCDEF")
    end
    File.open("#{remote_root}1/640/#{commercial_id}.jpg", "w") do |f|
      f.write("ABCDEFG")
    end
    File.open("#{remote_root}1/320/#{commercial_id}.jpg", "w") do |f|
      f.write("ABCDEFGH")
    end
    File.open("#{remote_root}1/960/#{disconnected_id}.jpg", "w") do |f|
      f.write("allcorrupted!")
    end
    File.open("#{remote_root}1/640/#{disconnected_id}.jpg", "w") do |f|
      f.write("allcorrupted!")
    end
    File.open("#{remote_root}1/320/#{disconnected_id}.jpg", "w") do |f|
      f.write("allcorrupted!")
    end
    File.open("#{remote_root}2/640/#{in_situ_id}.jpg", "w") do |f|
      f.write("correct")
    end
    File.open("#{remote_root}2/320/#{in_situ_id}.jpg", "w") do |f|
      f.write("correct")
    end
    File.open("#{remote_root}2/640/#{turned_over_id}.jpg", "w") do |f|
      f.write("ABCD")
    end
    File.open("#{remote_root}2/320/#{turned_over_id}.jpg", "w") do |f|
      f.write("ABCDE")
    end
    File.open("#{remote_root}2/640/#{commercial_id}.jpg", "w") do |f|
      f.write("allcorrupted!")
    end
    File.open("#{remote_root}2/320/#{commercial_id}.jpg", "w") do |f|
      f.write("allcorrupted!")
    end
    cmd = "#{script} --verbose 2>&1 > #{tempfile}"
    status = system(cmd)
    errors = File.read(tempfile)
    assert status, "Something went wrong with #{script}:\n#{errors}"
    assert_equal(<<-ERROR_TEXT.unindent, errors)
      Listing local 1280
      Listing local 320
      Listing local 640
      Listing local 960
      Listing local orig
      Listing local thumb
      Listing remote1 1280
      Listing remote1 320
      Listing remote1 640
      Listing remote1 960
      Listing remote1 orig
      Listing remote1 thumb
      Listing remote2 320
      Listing remote2 640
      Listing remote2 thumb
      Uploading 320/#{disconnected_id}.jpg to remote1
      Uploading 320/#{commercial_id}.jpg to remote2
      Uploading 320/#{disconnected_id}.jpg to remote2
      Uploading 640/#{disconnected_id}.jpg to remote1
      Uploading 640/#{commercial_id}.jpg to remote2
      Uploading 640/#{disconnected_id}.jpg to remote2
      Uploading 960/#{disconnected_id}.jpg to remote1
      Uploading orig/#{turned_over_id}.jpg to remote1
      Uploading orig/#{turned_over_id}.tiff to remote1
      Deleting 640/#{turned_over_id}.jpg
      Deleting 960/#{turned_over_id}.jpg
      Deleting 960/#{commercial_id}.jpg
    ERROR_TEXT
  end
end
