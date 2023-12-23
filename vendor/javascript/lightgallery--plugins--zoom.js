/*!
 * lightgallery | 2.7.2 | September 20th 2023
 * http://www.lightgalleryjs.com/
 * Copyright (c) 2020 Sachin Neravath;
 * @license GPLv3
 */
var __assign=function(){__assign=Object.assign||function __assign(e){for(var t,o=1,i=arguments.length;o<i;o++){t=arguments[o];for(var s in t)Object.prototype.hasOwnProperty.call(t,s)&&(e[s]=t[s])}return e};return __assign.apply(this,arguments)};var e={scale:1,zoom:true,infiniteZoom:true,actualSize:true,showZoomInOutIcons:false,actualSizeIcons:{zoomIn:"lg-zoom-in",zoomOut:"lg-zoom-out"},enableZoomAfter:300,zoomPluginStrings:{zoomIn:"Zoom in",zoomOut:"Zoom out",viewActualSize:"View actual size"}};var t={afterAppendSlide:"lgAfterAppendSlide",init:"lgInit",hasVideo:"lgHasVideo",containerResize:"lgContainerResize",updateSlides:"lgUpdateSlides",afterAppendSubHtml:"lgAfterAppendSubHtml",beforeOpen:"lgBeforeOpen",afterOpen:"lgAfterOpen",slideItemLoad:"lgSlideItemLoad",beforeSlide:"lgBeforeSlide",afterSlide:"lgAfterSlide",posterClick:"lgPosterClick",dragStart:"lgDragStart",dragMove:"lgDragMove",dragEnd:"lgDragEnd",beforeNextSlide:"lgBeforeNextSlide",beforePrevSlide:"lgBeforePrevSlide",beforeClose:"lgBeforeClose",afterClose:"lgAfterClose",rotateLeft:"lgRotateLeft",rotateRight:"lgRotateRight",flipHorizontal:"lgFlipHorizontal",flipVertical:"lgFlipVertical",autoplay:"lgAutoplay",autoplayStart:"lgAutoplayStart",autoplayStop:"lgAutoplayStop"};var o=500;var i=function(){function Zoom(t,o){this.core=t;this.$LG=o;this.settings=__assign(__assign({},e),this.core.settings);return this}Zoom.prototype.buildTemplates=function(){var e=this.settings.showZoomInOutIcons?'<button id="'+this.core.getIdName("lg-zoom-in")+'" type="button" aria-label="'+this.settings.zoomPluginStrings.zoomIn+'" class="lg-zoom-in lg-icon"></button><button id="'+this.core.getIdName("lg-zoom-out")+'" type="button" aria-label="'+this.settings.zoomPluginStrings.zoomIn+'" class="lg-zoom-out lg-icon"></button>':"";this.settings.actualSize&&(e+='<button id="'+this.core.getIdName("lg-actual-size")+'" type="button" aria-label="'+this.settings.zoomPluginStrings.viewActualSize+'" class="'+this.settings.actualSizeIcons.zoomIn+' lg-icon"></button>');this.core.outer.addClass("lg-use-transition-for-zoom");this.core.$toolbar.first().append(e)};Zoom.prototype.enableZoom=function(e){var t=this;var o=this.settings.enableZoomAfter+e.detail.delay;this.$LG("body").first().hasClass("lg-from-hash")&&e.detail.delay?o=0:this.$LG("body").first().removeClass("lg-from-hash");this.zoomableTimeout=setTimeout((function(){if(t.isImageSlide(t.core.index)){t.core.getSlideItem(e.detail.index).addClass("lg-zoomable");e.detail.index===t.core.index&&t.setZoomEssentials()}}),o+30)};Zoom.prototype.enableZoomOnSlideItemLoad=function(){this.core.LGel.on(t.slideItemLoad+".zoom",this.enableZoom.bind(this))};Zoom.prototype.getDragCords=function(e){return{x:e.pageX,y:e.pageY}};Zoom.prototype.getSwipeCords=function(e){var t=e.touches[0].pageX;var o=e.touches[0].pageY;return{x:t,y:o}};Zoom.prototype.getDragAllowedAxises=function(e,t){var o=this.core.getSlideItem(this.core.index).find(".lg-image").first().get();var i=0;var s=0;var a=o.getBoundingClientRect();if(e){i=o.offsetHeight*e;s=o.offsetWidth*e}else if(t){i=a.height+t*a.height;s=a.width+t*a.width}else{i=a.height;s=a.width}var r=i>this.containerRect.height;var n=s>this.containerRect.width;return{allowX:n,allowY:r}};Zoom.prototype.setZoomEssentials=function(){this.containerRect=this.core.$content.get().getBoundingClientRect()};
/**
     * @desc Image zoom
     * Translate the wrap and scale the image to get better user experience
     *
     * @param {String} scale - Zoom decrement/increment value
     */Zoom.prototype.zoomImage=function(e,t,o,i){if(!(Math.abs(t)<=0)){var s=this.containerRect.width/2+this.containerRect.left;var a=this.containerRect.height/2+this.containerRect.top+this.scrollTop;var r;var n;1===e&&(this.positionChanged=false);var l=this.getDragAllowedAxises(0,t);var g=l.allowY,c=l.allowX;if(this.positionChanged){r=this.left/(this.scale-t);n=this.top/(this.scale-t);this.pageX=s-r;this.pageY=a-n;this.positionChanged=false}var m=this.getPossibleSwipeDragCords(t);var h;var u;var d=s-this.pageX;var f=a-this.pageY;if(e-t>1){var p=(e-t)/Math.abs(t);d=(t<0?-d:d)+this.left*(p+(t<0?-1:1));f=(t<0?-f:f)+this.top*(p+(t<0?-1:1));h=d/p;u=f/p}else{p=(e-t)*t;h=d*p;u=f*p}if(o){c?this.isBeyondPossibleLeft(h,m.minX)?h=m.minX:this.isBeyondPossibleRight(h,m.maxX)&&(h=m.maxX):e>1&&(h<m.minX?h=m.minX:h>m.maxX&&(h=m.maxX));g?this.isBeyondPossibleTop(u,m.minY)?u=m.minY:this.isBeyondPossibleBottom(u,m.maxY)&&(u=m.maxY):e>1&&(u<m.minY?u=m.minY:u>m.maxY&&(u=m.maxY))}this.setZoomStyles({x:h,y:u,scale:e});this.left=h;this.top=u;i&&this.setZoomImageSize()}};Zoom.prototype.resetImageTranslate=function(e){if(this.isImageSlide(e)){var t=this.core.getSlideItem(e).find(".lg-image").first();this.imageReset=false;t.removeClass("reset-transition reset-transition-y reset-transition-x");this.core.outer.removeClass("lg-actual-size");t.css("width","auto").css("height","auto");setTimeout((function(){t.removeClass("no-transition")}),10)}};Zoom.prototype.setZoomImageSize=function(){var e=this;var t=this.core.getSlideItem(this.core.index).find(".lg-image").first();setTimeout((function(){var o=e.getCurrentImageActualSizeScale();if(e.scale>=o){t.addClass("no-transition");e.imageReset=true}}),o);setTimeout((function(){var o=e.getCurrentImageActualSizeScale();if(e.scale>=o){var i=e.getDragAllowedAxises(e.scale);t.css("width",t.get().naturalWidth+"px").css("height",t.get().naturalHeight+"px");e.core.outer.addClass("lg-actual-size");i.allowX&&i.allowY?t.addClass("reset-transition"):i.allowX&&!i.allowY?t.addClass("reset-transition-x"):!i.allowX&&i.allowY&&t.addClass("reset-transition-y")}}),o+50)};
/**
     * @desc apply scale3d to image and translate to image wrap
     * @param {style} X,Y and scale
     */Zoom.prototype.setZoomStyles=function(e){var t=this.core.getSlideItem(this.core.index).find(".lg-img-wrap").first();var o=this.core.getSlideItem(this.core.index).find(".lg-image").first();var i=this.core.outer.find(".lg-current .lg-dummy-img").first();this.scale=e.scale;o.css("transform","scale3d("+e.scale+", "+e.scale+", 1)");i.css("transform","scale3d("+e.scale+", "+e.scale+", 1)");var s="translate3d("+e.x+"px, "+e.y+"px, 0)";t.css("transform",s)};
/**
     * @param index - Index of the current slide
     * @param event - event will be available only if the function is called on clicking/taping the imags
     */Zoom.prototype.setActualSize=function(e,t){var i=this;if(!this.zoomInProgress){this.zoomInProgress=true;var s=this.core.galleryItems[this.core.index];this.resetImageTranslate(e);setTimeout((function(){if(s.src&&!i.core.outer.hasClass("lg-first-slide-loading")){var e=i.getCurrentImageActualSizeScale();var o=i.scale;i.core.outer.hasClass("lg-zoomed")?i.scale=1:i.scale=i.getScale(e);i.setPageCords(t);i.beginZoom(i.scale);i.zoomImage(i.scale,i.scale-o,true,true)}}),50);setTimeout((function(){i.core.outer.removeClass("lg-grabbing").addClass("lg-grab")}),60);setTimeout((function(){i.zoomInProgress=false}),o+110)}};Zoom.prototype.getNaturalWidth=function(e){var t=this.core.getSlideItem(e).find(".lg-image").first();var o=this.core.galleryItems[e].width;return o?parseFloat(o):t.get().naturalWidth};Zoom.prototype.getActualSizeScale=function(e,t){var o;var i;if(e>=t){o=e/t;i=o||2}else i=1;return i};Zoom.prototype.getCurrentImageActualSizeScale=function(){var e=this.core.getSlideItem(this.core.index).find(".lg-image").first();var t=e.get().offsetWidth;var o=this.getNaturalWidth(this.core.index)||t;return this.getActualSizeScale(o,t)};Zoom.prototype.getPageCords=function(e){var t={};if(e){t.x=e.pageX||e.touches[0].pageX;t.y=e.pageY||e.touches[0].pageY}else{var o=this.core.$content.get().getBoundingClientRect();t.x=o.width/2+o.left;t.y=o.height/2+this.scrollTop+o.top}return t};Zoom.prototype.setPageCords=function(e){var t=this.getPageCords(e);this.pageX=t.x;this.pageY=t.y};Zoom.prototype.manageActualPixelClassNames=function(){var e=this.core.getElementById("lg-actual-size");e.removeClass(this.settings.actualSizeIcons.zoomIn).addClass(this.settings.actualSizeIcons.zoomOut)};Zoom.prototype.beginZoom=function(e){this.core.outer.removeClass("lg-zoom-drag-transition lg-zoom-dragging");if(e>1){this.core.outer.addClass("lg-zoomed");this.manageActualPixelClassNames()}else this.resetZoom();return e>1};Zoom.prototype.getScale=function(e){var t=this.getCurrentImageActualSizeScale();e<1?e=1:e>t&&(e=t);return e};Zoom.prototype.init=function(){var e=this;if(this.settings.zoom){this.buildTemplates();this.enableZoomOnSlideItemLoad();var o=null;this.core.outer.on("dblclick.lg",(function(t){e.$LG(t.target).hasClass("lg-image")&&e.setActualSize(e.core.index,t)}));this.core.outer.on("touchstart.lg",(function(t){var i=e.$LG(t.target);if(1===t.touches.length&&i.hasClass("lg-image"))if(o){clearTimeout(o);o=null;t.preventDefault();e.setActualSize(e.core.index,t)}else o=setTimeout((function(){o=null}),300)}));this.core.LGel.on(t.containerResize+".zoom "+t.rotateRight+".zoom "+t.rotateLeft+".zoom "+t.flipHorizontal+".zoom "+t.flipVertical+".zoom",(function(){if(e.core.lgOpened&&e.isImageSlide(e.core.index)&&!e.core.touchAction){var t=e.core.getSlideItem(e.core.index).find(".lg-img-wrap").first();e.top=0;e.left=0;e.setZoomEssentials();e.setZoomSwipeStyles(t,{x:0,y:0});e.positionChanged=true}}));this.$LG(window).on("scroll.lg.zoom.global"+this.core.lgId,(function(){e.core.lgOpened&&(e.scrollTop=e.$LG(window).scrollTop())}));this.core.getElementById("lg-zoom-out").on("click.lg",(function(){if(e.isImageSlide(e.core.index)){var t=0;if(e.imageReset){e.resetImageTranslate(e.core.index);t=50}setTimeout((function(){var t=e.scale-e.settings.scale;t<1&&(t=1);e.beginZoom(t);e.zoomImage(t,-e.settings.scale,true,!e.settings.infiniteZoom)}),t)}}));this.core.getElementById("lg-zoom-in").on("click.lg",(function(){e.zoomIn()}));this.core.getElementById("lg-actual-size").on("click.lg",(function(){e.setActualSize(e.core.index)}));this.core.LGel.on(t.beforeOpen+".zoom",(function(){e.core.outer.find(".lg-item").removeClass("lg-zoomable")}));this.core.LGel.on(t.afterOpen+".zoom",(function(){e.scrollTop=e.$LG(window).scrollTop();e.pageX=e.core.outer.width()/2;e.pageY=e.core.outer.height()/2+e.scrollTop;e.scale=1}));this.core.LGel.on(t.afterSlide+".zoom",(function(t){var o=t.detail.prevIndex;e.scale=1;e.positionChanged=false;e.zoomInProgress=false;e.resetZoom(o);e.resetImageTranslate(o);e.isImageSlide(e.core.index)&&e.setZoomEssentials()}));this.zoomDrag();this.pinchZoom();this.zoomSwipe();this.zoomableTimeout=false;this.positionChanged=false;this.zoomInProgress=false}};Zoom.prototype.zoomIn=function(){if(this.isImageSlide(this.core.index)){var e=this.scale+this.settings.scale;this.settings.infiniteZoom||(e=this.getScale(e));this.beginZoom(e);this.zoomImage(e,Math.min(this.settings.scale,e-this.scale),true,!this.settings.infiniteZoom)}};Zoom.prototype.resetZoom=function(e){this.core.outer.removeClass("lg-zoomed lg-zoom-drag-transition");var t=this.core.getElementById("lg-actual-size");var o=this.core.getSlideItem(void 0!==e?e:this.core.index);t.removeClass(this.settings.actualSizeIcons.zoomOut).addClass(this.settings.actualSizeIcons.zoomIn);o.find(".lg-img-wrap").first().removeAttr("style");o.find(".lg-image").first().removeAttr("style");this.scale=1;this.left=0;this.top=0;this.setPageCords()};Zoom.prototype.getTouchDistance=function(e){return Math.sqrt((e.touches[0].pageX-e.touches[1].pageX)*(e.touches[0].pageX-e.touches[1].pageX)+(e.touches[0].pageY-e.touches[1].pageY)*(e.touches[0].pageY-e.touches[1].pageY))};Zoom.prototype.pinchZoom=function(){var e=this;var t=0;var o=false;var i=1;var s=0;var a=this.core.getSlideItem(this.core.index);this.core.outer.on("touchstart.lg",(function(o){a=e.core.getSlideItem(e.core.index);if(e.isImageSlide(e.core.index)&&2===o.touches.length){o.preventDefault();if(e.core.outer.hasClass("lg-first-slide-loading"))return;i=e.scale||1;e.core.outer.removeClass("lg-zoom-drag-transition lg-zoom-dragging");e.setPageCords(o);e.resetImageTranslate(e.core.index);e.core.touchAction="pinch";t=e.getTouchDistance(o)}}));this.core.$inner.on("touchmove.lg",(function(r){if(2===r.touches.length&&"pinch"===e.core.touchAction&&(e.$LG(r.target).hasClass("lg-item")||a.get().contains(r.target))){r.preventDefault();var n=e.getTouchDistance(r);var l=t-n;!o&&Math.abs(l)>5&&(o=true);if(o){s=e.scale;var g=Math.max(1,i+.02*-l);e.scale=Math.round(100*(g+Number.EPSILON))/100;var c=e.scale-s;e.zoomImage(e.scale,Math.round(100*(c+Number.EPSILON))/100,false,false)}}}));this.core.$inner.on("touchend.lg",(function(i){if("pinch"===e.core.touchAction&&(e.$LG(i.target).hasClass("lg-item")||a.get().contains(i.target))){o=false;t=0;if(e.scale<=1)e.resetZoom();else{var s=e.getCurrentImageActualSizeScale();if(e.scale>=s){var r=s-e.scale;0===r&&(r=.01);e.zoomImage(s,r,false,true)}e.manageActualPixelClassNames();e.core.outer.addClass("lg-zoomed")}e.core.touchAction=void 0}}))};Zoom.prototype.touchendZoom=function(e,t,o,i,s){var a=t.x-e.x;var r=t.y-e.y;var n=Math.abs(a)/s+1;var l=Math.abs(r)/s+1;n>2&&(n+=1);l>2&&(l+=1);a*=n;r*=l;var g=this.core.getSlideItem(this.core.index).find(".lg-img-wrap").first();var c={};c.x=this.left+a;c.y=this.top+r;var m=this.getPossibleSwipeDragCords();if(Math.abs(a)>15||Math.abs(r)>15){i&&(this.isBeyondPossibleTop(c.y,m.minY)?c.y=m.minY:this.isBeyondPossibleBottom(c.y,m.maxY)&&(c.y=m.maxY));o&&(this.isBeyondPossibleLeft(c.x,m.minX)?c.x=m.minX:this.isBeyondPossibleRight(c.x,m.maxX)&&(c.x=m.maxX));i?this.top=c.y:c.y=this.top;o?this.left=c.x:c.x=this.left;this.setZoomSwipeStyles(g,c);this.positionChanged=true}};Zoom.prototype.getZoomSwipeCords=function(e,t,o,i,s){var a={};if(i){a.y=this.top+(t.y-e.y);if(this.isBeyondPossibleTop(a.y,s.minY)){var r=s.minY-a.y;a.y=s.minY-r/6}else if(this.isBeyondPossibleBottom(a.y,s.maxY)){var n=a.y-s.maxY;a.y=s.maxY+n/6}}else a.y=this.top;if(o){a.x=this.left+(t.x-e.x);if(this.isBeyondPossibleLeft(a.x,s.minX)){var l=s.minX-a.x;a.x=s.minX-l/6}else if(this.isBeyondPossibleRight(a.x,s.maxX)){var g=a.x-s.maxX;a.x=s.maxX+g/6}}else a.x=this.left;return a};Zoom.prototype.isBeyondPossibleLeft=function(e,t){return e>=t};Zoom.prototype.isBeyondPossibleRight=function(e,t){return e<=t};Zoom.prototype.isBeyondPossibleTop=function(e,t){return e>=t};Zoom.prototype.isBeyondPossibleBottom=function(e,t){return e<=t};Zoom.prototype.isImageSlide=function(e){var t=this.core.galleryItems[e];return"image"===this.core.getSlideType(t)};Zoom.prototype.getPossibleSwipeDragCords=function(e){var t=this.core.getSlideItem(this.core.index).find(".lg-image").first();var o=this.core.mediaContainerPosition.bottom;var i=t.get().getBoundingClientRect();var s=i.height;var a=i.width;if(e){s+=e*s;a+=e*a}var r=(s-this.containerRect.height)/2;var n=(this.containerRect.height-s)/2+o;var l=(a-this.containerRect.width)/2;var g=(this.containerRect.width-a)/2;var c={minY:r,maxY:n,minX:l,maxX:g};return c};Zoom.prototype.setZoomSwipeStyles=function(e,t){e.css("transform","translate3d("+t.x+"px, "+t.y+"px, 0)")};Zoom.prototype.zoomSwipe=function(){var e=this;var t={};var o={};var i=false;var s=false;var a=false;var r=new Date;var n=new Date;var l;var g;var c=this.core.getSlideItem(this.core.index);this.core.$inner.on("touchstart.lg",(function(o){if(e.isImageSlide(e.core.index)){c=e.core.getSlideItem(e.core.index);if((e.$LG(o.target).hasClass("lg-item")||c.get().contains(o.target))&&1===o.touches.length&&e.core.outer.hasClass("lg-zoomed")){o.preventDefault();r=new Date;e.core.touchAction="zoomSwipe";g=e.core.getSlideItem(e.core.index).find(".lg-img-wrap").first();var i=e.getDragAllowedAxises(0);a=i.allowY;s=i.allowX;(s||a)&&(t=e.getSwipeCords(o));l=e.getPossibleSwipeDragCords();e.core.outer.addClass("lg-zoom-dragging lg-zoom-drag-transition")}}}));this.core.$inner.on("touchmove.lg",(function(r){if(1===r.touches.length&&"zoomSwipe"===e.core.touchAction&&(e.$LG(r.target).hasClass("lg-item")||c.get().contains(r.target))){r.preventDefault();e.core.touchAction="zoomSwipe";o=e.getSwipeCords(r);var n=e.getZoomSwipeCords(t,o,s,a,l);if(Math.abs(o.x-t.x)>15||Math.abs(o.y-t.y)>15){i=true;e.setZoomSwipeStyles(g,n)}}}));this.core.$inner.on("touchend.lg",(function(l){if("zoomSwipe"===e.core.touchAction&&(e.$LG(l.target).hasClass("lg-item")||c.get().contains(l.target))){l.preventDefault();e.core.touchAction=void 0;e.core.outer.removeClass("lg-zoom-dragging");if(!i)return;i=false;n=new Date;var g=n.valueOf()-r.valueOf();e.touchendZoom(t,o,s,a,g)}}))};Zoom.prototype.zoomDrag=function(){var e=this;var t={};var o={};var i=false;var s=false;var a=false;var r=false;var n;var l;var g;var c;this.core.outer.on("mousedown.lg.zoom",(function(o){if(e.isImageSlide(e.core.index)){var s=e.core.getSlideItem(e.core.index);if(e.$LG(o.target).hasClass("lg-item")||s.get().contains(o.target)){n=new Date;c=e.core.getSlideItem(e.core.index).find(".lg-img-wrap").first();var l=e.getDragAllowedAxises(0);r=l.allowY;a=l.allowX;if(e.core.outer.hasClass("lg-zoomed")&&e.$LG(o.target).hasClass("lg-object")&&(a||r)){o.preventDefault();t=e.getDragCords(o);g=e.getPossibleSwipeDragCords();i=true;e.core.outer.removeClass("lg-grab").addClass("lg-grabbing lg-zoom-drag-transition lg-zoom-dragging")}}}}));this.$LG(window).on("mousemove.lg.zoom.global"+this.core.lgId,(function(n){if(i){s=true;o=e.getDragCords(n);var l=e.getZoomSwipeCords(t,o,a,r,g);e.setZoomSwipeStyles(c,l)}}));this.$LG(window).on("mouseup.lg.zoom.global"+this.core.lgId,(function(g){if(i){l=new Date;i=false;e.core.outer.removeClass("lg-zoom-dragging");if(s&&(t.x!==o.x||t.y!==o.y)){o=e.getDragCords(g);var c=l.valueOf()-n.valueOf();e.touchendZoom(t,o,a,r,c)}s=false}e.core.outer.removeClass("lg-grabbing").addClass("lg-grab")}))};Zoom.prototype.closeGallery=function(){this.resetZoom();this.zoomInProgress=false};Zoom.prototype.destroy=function(){this.$LG(window).off(".lg.zoom.global"+this.core.lgId);this.core.LGel.off(".lg.zoom");this.core.LGel.off(".zoom");clearTimeout(this.zoomableTimeout);this.zoomableTimeout=false};return Zoom}();export{i as default};

