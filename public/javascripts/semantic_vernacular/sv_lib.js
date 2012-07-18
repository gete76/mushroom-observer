/* Javascript helpers for the semantic vernacular module.
/*
/******************************************************************************/

jQuery.noConflict();

// Namespaces.
if (window.org == undefined || typeof(org) != "object") 
  org = {};
if (org.mo == undefined || typeof(org.mo) != "object") 
  org.mo = {};
if (org.mo.sv == undefined || typeof(org.mo.sv) != "object") 
  org.mo.sv = {};
if (org.mo.sv.show == undefined || typeof(org.mo.sv.show) != "object") 
  org.mo.sv.show = {};
if (org.mo.sv.create == undefined || typeof(org.mo.sv.create) != "object") 
  org.mo.sv.create = {};

// Global variables.
// The RPI SparqlProxy web service url.
org.mo.sv.sparqlProxy = "http://logd.tw.rpi.edu/ws/sparqlproxy.php";
// The triple store endpoint url.
//org.mo.sv.endpoint = "http://aquarius.tw.rpi.edu:2024/sparql";
org.mo.sv.endpoint = "http://128.128.170.15:3030/svf/sparql";
// SVF ontology namespace.
org.mo.sv.SVFNamespace = "http://mushroomobserver.org/svf.owl#";
// A global object to hold all the input data.
org.mo.sv.create.inputData = {
  "svd": {
    "id": null,
    "uri": null,
    "is_new":null
  },
  "label": {
    "id": null,
    "uri": null,
    "value": null,
    "is_default": null
  },
  "definition": {
    "id": null,
    "uri": null,
    "is_default": null
  },
  "features": [], 
  "scientific_names": [],
  "matched_svds": [],
  "user": {
    "uri": "http://mushroomobserver.org/svf.owl#U2"
  }
};

// Empty inputData.
org.mo.sv.clearInputData = function()
{
  org.mo.sv.create.inputData = {
    "svd": {
      "id": null,
      "uri": null,
      "is_new":null
    },
    "label": {
      "id": null,
      "uri": null,
      "value": null,
      "is_default": null
    },
    "definition": {
      "id": null,
      "uri": null,
      "is_default": null
    },
    "features": [], 
    "scientific_names": [],
    "matched_svds": [],
    "user": {
      "uri": "http://mushroomobserver.org/svf.owl#U2"
    }
  };
};

// Submit a SPARQL query to the endpoint via the RPI SparqlProxy service.
org.mo.sv.submitQuery = function(query, callback, output)
{
  if (typeof output == "undefined")
    output = "json";
  // var url = org.mo.sv.sparqlProxy + "?" 
  //           + "query=" + encodeURIComponent(query)
  //           + "&service-uri=" + encodeURIComponent(org.mo.sv.endpoint)
  //           + "&output=" + output;
  var url = org.mo.sv.endpoint + "?" 
            + "query=" + encodeURIComponent(query)
            + "&output=" + encodeURIComponent(output);
  org.mo.sv.ajax(url, "GET", "", callback);
};

// Ajax function.
org.mo.sv.ajax = function(url, method, data, callback)
{
  if (jQuery.browser.msie && 
      parseInt(jQuery.browser.version, 10) >= 7 && window.XDomainRequest) {
    // Use Microsoft XDR
    var xdr = new XDomainRequest();
    xdr.open(method, url);
    xdr.onload = function () {
      callback(xdr.responseText);
    };
    xdr.send(data);
  } 
  else
    jQuery.ajax({
      url: url,
      type: method,
      data: data,
      dataType: "json",
      success: callback,
      failure: function(msg) {
        alert(msg);
      }
    });
};

// Build a query to ask for the maximum id for a type of resources.
org.mo.sv.askMaxID = function(type)
{
  var query = org.mo.sv.getQueryPrefix();
  query += "SELECT ?id WHERE {";
  switch (type) {
    case "SemanticVernacularDescription":
    case "VernacularDefinition":
    case "ScientificName":
      query += "?uri rdfs:subClassOf svf:" + type + " . ";
      break;
    case "VernacularLabel":
    case "User":
      query+= "?uri a svf:" + type + " . ";
      break;
  }
  query += "?uri svf:hasID ?id }";
  query += "ORDER BY DESC (?id) LIMIT 1"
  return query;
};

// Build a query to ask for the existence of an URI.
org.mo.sv.askURI = function(uri)
{
  var query = org.mo.sv.getQueryPrefix();
  query += "ASK { <" + uri + "> ?p ?o }";
  return query;
};

// Build a query to ask for the existence of a label.
org.mo.sv.askLabel = function(label)
{
  var query = org.mo.sv.getQueryPrefix();
  query += "ASK { ?s rdfs:label \"" + label + "\"^^rdfs:Literal }";
  return query;
};

// Build a query to get features dependent on selected feature-value pairs.
org.mo.sv.create.queryDependentFeatures = function(feature, values)
{
  var query = org.mo.sv.getQueryPrefix();
  query += "SELECT DISTINCT ?uri ?label WHERE {";
  query += "?uri rdfs:subPropertyOf+ svf:hasFungalFeature . ";
  query += "?uri rdfs:label ?label . ";
  query += "?uri rdfs:domain ?c1 . ";
  query += "?c1 owl:intersectionOf ?c2 . ";
  query += "{ ?c2 rdf:rest+/rdf:first ?c3 } UNION "
  query += "{ ?c2 rdf:rest+/rdf:first ?c4 . ";
  query += "?c4 owl:unionOf ?c5 . ";
  query += "?c5 rdf:rest+/rdf:first ?c3 . }";
  var arr = [];
  jQuery.each(values, function(i, val) {
    var str = "{?c3 owl:onProperty <" + feature + "> . ";
    str += "?c3 owl:someValuesFrom <" + val + "> . }";
    arr.push(str);
  });
  query += arr.join(" UNION ");
  query += "}";
  return query;
};

// Build a query to get available SVDs for selected feature-value pairs.
org.mo.sv.create.querySVDForFeatureValue = function(feature, values)
{
  var query = org.mo.sv.getQueryPrefix();
  query += "SELECT DISTINCT ?uri ?label WHERE {";
  query += "?uri rdfs:subClassOf svf:SemanticVernacularDescription . ";
  query += "?uri rdfs:subClassOf ?c1 . ";
  query += "?c1 owl:onProperty svf:hasLabel . ";
  query += "?c1 owl:hasValue ?vl . ";
  query += "?vl svf:isDefault \"true\"^^xsd:boolean . "
  query += "?vl rdfs:label ?label . ";
  query += "?uri rdfs:subClassOf ?c2 . ";
  query += "?c2 owl:onProperty svf:hasDefinition . ";
  query += "?c2 owl:someValuesFrom ?desc . ";
  query += "?desc owl:equivalentClass ?c3 . ";
  query += "?c3 owl:intersectionOf ?c4 . "; 
  query += "{ ?c4 rdf:rest+/rdf:first ?c5 . } UNION ";
  query += "{ ?c4 rdf:rest+/rdf:first ?c6 . ";
  query += "?c6 owl:unionOf ?c7 . ";
  query += "?c7 rdf:rest+/rdf:first ?c5 . }";
  query += "?desc rdfs:subClassOf ?c8 . ";
  query += "?c8 owl:onProperty svf:isDefault . ";
  query += "?c8 owl:hasValue \"true\"^^xsd:boolean . ";
  var arr = [];
  jQuery.each(values, function(i, val) {
    var str = "{ ?c5 owl:onProperty <" + feature + "> . ";
    str += "?c5 owl:someValuesFrom <" + val + "> . }";
    arr.push(str);
  });
  query += arr.join(" UNION ");
  query += "}";
  return query;
};

// Build a query to get values for a selected feature.
org.mo.sv.create.queryFeatureValues = function(feature)
{
  var query = org.mo.sv.getQueryPrefix();
  query += "SELECT DISTINCT ?uri ?label WHERE {";
  query += "<" + feature + "> rdfs:range ?r . ";
  query += "?r owl:equivalentClass ?c . ";
  query += "?c owl:unionOf ?u . ";
  query += "?u rdf:rest*/rdf:first ?uri . ";
  query += "?uri rdfs:label ?label . }";
  return query;
};

// Build a query to get all independent features.
org.mo.sv.create.queryIndependentFeatures = function()
{
  var query = org.mo.sv.getQueryPrefix();
  query += "SELECT DISTINCT ?uri ?label WHERE {";
  query += "?uri rdfs:subPropertyOf svf:hasFungalFeature . ";
  query += "?uri rdfs:label ?label . ";
  query += "FILTER (!EXISTS ";
  query += "{ ?uri rdfs:domain ?domain . ";
  query += "?domain owl:intersectionOf ?c . })";
  query += "FILTER (!EXISTS ";
  query += "{ ?uri rdfs:label \"has color\"^^rdfs:Literal . })";
  query += "FILTER (!EXISTS ";
  query += "{ ?uri rdfs:label \"has status\"^^rdfs:Literal . })}";
  return query;
};

// Get all query prefixes.
org.mo.sv.getQueryPrefix = function()
{
  var prefix = "PREFIX owl: <http://www.w3.org/2002/07/owl#>";
  prefix += "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>";
  prefix += "PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>";
  prefix += "PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>";
  prefix += "PREFIX svf: <" + org.mo.sv.SVFNamespace + ">";
  return prefix;
};