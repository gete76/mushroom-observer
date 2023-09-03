var t = "undefined" !== typeof globalThis ? globalThis : "undefined" !== typeof self ? self : global; var e = {}; (function () { var n = this || t; (function () { (function () { (this || t).Rails = { linkClickSelector: "a[data-confirm], a[data-method], a[data-remote]:not([disabled]), a[data-disable-with], a[data-disable]", buttonClickSelector: { selector: "button[data-remote]:not([form]), button[data-confirm]:not([form])", exclude: "form button" }, inputChangeSelector: "select[data-remote], input[data-remote], textarea[data-remote]", formSubmitSelector: "form:not([data-turbo=true])", formInputClickSelector: "form:not([data-turbo=true]) input[type=submit], form:not([data-turbo=true]) input[type=image], form:not([data-turbo=true]) button[type=submit], form:not([data-turbo=true]) button:not([type]), input[type=submit][form], input[type=image][form], button[type=submit][form], button[form]:not([type])", formDisableSelector: "input[data-disable-with]:enabled, button[data-disable-with]:enabled, textarea[data-disable-with]:enabled, input[data-disable]:enabled, button[data-disable]:enabled, textarea[data-disable]:enabled", formEnableSelector: "input[data-disable-with]:disabled, button[data-disable-with]:disabled, textarea[data-disable-with]:disabled, input[data-disable]:disabled, button[data-disable]:disabled, textarea[data-disable]:disabled", fileInputSelector: "input[name][type=file]:not([disabled])", linkDisableSelector: "a[data-disable-with], a[data-disable]", buttonDisableSelector: "button[data-remote][data-disable-with], button[data-remote][data-disable]" } }).call(this || t) }).call(n); var a = n.Rails; (function () { (function () { var t; t = null; a.loadCSPNonce = function () { var e; return t = null != (e = document.querySelector("meta[name=csp-nonce]")) ? e.content : void 0 }; a.cspNonce = function () { return null != t ? t : a.loadCSPNonce() } }).call(this || t); (function () { var t, e; e = Element.prototype.matches || Element.prototype.matchesSelector || Element.prototype.mozMatchesSelector || Element.prototype.msMatchesSelector || Element.prototype.oMatchesSelector || Element.prototype.webkitMatchesSelector; a.matches = function (t, n) { return null != n.exclude ? e.call(t, n.selector) && !e.call(t, n.exclude) : e.call(t, n) }; t = "_ujsData"; a.getData = function (e, n) { var a; return null != (a = e[t]) ? a[n] : void 0 }; a.setData = function (e, n, a) { null == e[t] && (e[t] = {}); return e[t][n] = a }; a.isContentEditable = function (t) { var e; e = false; while (true) { if (t.isContentEditable) { e = true; break } t = t.parentElement; if (!t) break } return e }; a.$ = function (t) { return Array.prototype.slice.call(document.querySelectorAll(t)) } }).call(this || t); (function () { var t, e, n; t = a.$; n = a.csrfToken = function () { var t; t = document.querySelector("meta[name=csrf-token]"); return t && t.content }; e = a.csrfParam = function () { var t; t = document.querySelector("meta[name=csrf-param]"); return t && t.content }; a.CSRFProtection = function (t) { var e; e = n(); if (null != e) return t.setRequestHeader("X-CSRF-Token", e) }; a.refreshCSRFTokens = function () { var a, r; r = n(); a = e(); if (null != r && null != a) return t('form input[name="' + a + '"]').forEach((function (t) { return t.value = r })) } }).call(this || t); (function () { var e, n, r, o; r = a.matches; e = window.CustomEvent; if ("function" !== typeof e) { e = function (t, e) { var n; n = document.createEvent("CustomEvent"); n.initCustomEvent(t, e.bubbles, e.cancelable, e.detail); return n }; e.prototype = window.Event.prototype; o = e.prototype.preventDefault; e.prototype.preventDefault = function () { var e; e = o.call(this || t); (this || t).cancelable && !(this || t).defaultPrevented && Object.defineProperty(this || t, "defaultPrevented", { get: function () { return true } }); return e } } n = a.fire = function (t, n, a) { var r; r = new e(n, { bubbles: true, cancelable: true, detail: a }); t.dispatchEvent(r); return !r.defaultPrevented }; a.stopEverything = function (t) { n(t.target, "ujs:everythingStopped"); t.preventDefault(); t.stopPropagation(); return t.stopImmediatePropagation() }; a.delegate = function (t, e, n, a) { return t.addEventListener(n, (function (t) { var n; n = t.target; while (!(!(n instanceof Element) || r(n, e))) n = n.parentNode; if (n instanceof Element && false === a.call(n, t)) { t.preventDefault(); return t.stopPropagation() } })) } }).call(this || t); (function () { var t, e, n, r, o, i; r = a.cspNonce, e = a.CSRFProtection, a.fire; t = { "*": "*/*", text: "text/plain", html: "text/html", xml: "application/xml, text/xml", json: "application/json, text/javascript", script: "text/javascript, application/javascript, application/ecmascript, application/x-ecmascript" }; a.ajax = function (t) { var e; t = o(t); e = n(t, (function () { var n, a; a = i(null != (n = e.response) ? n : e.responseText, e.getResponseHeader("Content-Type")); 2 === Math.floor(e.status / 100) ? "function" === typeof t.success && t.success(a, e.statusText, e) : "function" === typeof t.error && t.error(a, e.statusText, e); return "function" === typeof t.complete ? t.complete(e, e.statusText) : void 0 })); return !(null != t.beforeSend && !t.beforeSend(e, t)) && (e.readyState === XMLHttpRequest.OPENED ? e.send(t.data) : void 0) }; o = function (e) { e.url = e.url || location.href; e.type = e.type.toUpperCase(); "GET" === e.type && e.data && (e.url.indexOf("?") < 0 ? e.url += "?" + e.data : e.url += "&" + e.data); null == t[e.dataType] && (e.dataType = "*"); e.accept = t[e.dataType]; "*" !== e.dataType && (e.accept += ", */*; q=0.01"); return e }; n = function (t, n) { var a; a = new XMLHttpRequest; a.open(t.type, t.url, true); a.setRequestHeader("Accept", t.accept); "string" === typeof t.data && a.setRequestHeader("Content-Type", "application/x-www-form-urlencoded; charset=UTF-8"); if (!t.crossDomain) { a.setRequestHeader("X-Requested-With", "XMLHttpRequest"); e(a) } a.withCredentials = !!t.withCredentials; a.onreadystatechange = function () { if (a.readyState === XMLHttpRequest.DONE) return n(a) }; return a }; i = function (t, e) { var n, a; if ("string" === typeof t && "string" === typeof e) if (e.match(/\bjson\b/)) try { t = JSON.parse(t) } catch (t) { } else if (e.match(/\b(?:java|ecma)script\b/)) { a = document.createElement("script"); a.setAttribute("nonce", r()); a.text = t; document.head.appendChild(a).parentNode.removeChild(a) } else if (e.match(/\b(xml|html|svg)\b/)) { n = new DOMParser; e = e.replace(/;.+/, ""); try { t = n.parseFromString(t, e) } catch (t) { } } return t }; a.href = function (t) { return t.href }; a.isCrossDomain = function (t) { var e, n; e = document.createElement("a"); e.href = location.href; n = document.createElement("a"); try { n.href = t; return !((!n.protocol || ":" === n.protocol) && !n.host || e.protocol + "//" + e.host === n.protocol + "//" + n.host) } catch (t) { t; return true } } }).call(this || t); (function () { var t, e; t = a.matches; e = function (t) { return Array.prototype.slice.call(t) }; a.serializeElement = function (n, a) { var r, o; r = [n]; t(n, "form") && (r = e(n.elements)); o = []; r.forEach((function (n) { if (n.name && !n.disabled && !t(n, "fieldset[disabled] *")) return t(n, "select") ? e(n.options).forEach((function (t) { if (t.selected) return o.push({ name: n.name, value: t.value }) })) : n.checked || -1 === ["radio", "checkbox", "submit"].indexOf(n.type) ? o.push({ name: n.name, value: n.value }) : void 0 })); a && o.push(a); return o.map((function (t) { return null != t.name ? encodeURIComponent(t.name) + "=" + encodeURIComponent(t.value) : t })).join("&") }; a.formElements = function (n, a) { return t(n, "form") ? e(n.elements).filter((function (e) { return t(e, a) })) : e(n.querySelectorAll(a)) } }).call(this || t); (function () { var e, n, r; n = a.fire, r = a.stopEverything; a.handleConfirm = function (n) { if (!e(this || t)) return r(n) }; a.confirm = function (t, e) { return confirm(t) }; e = function (t) { var e, r, o; o = t.getAttribute("data-confirm"); if (!o) return true; e = false; if (n(t, "confirm")) { try { e = a.confirm(o, t) } catch (t) { } r = n(t, "confirm:complete", [e]) } return e && r } }).call(this || t); (function () { var e, n, r, o, i, l, u, c, s, d, f, m, b; f = a.matches, c = a.getData, m = a.setData, b = a.stopEverything, u = a.formElements, s = a.isContentEditable; a.handleDisabledElement = function (e) { var n; n = this || t; if (n.disabled) return b(e) }; a.enableElement = function (t) { var e; if (t instanceof Event) { if (d(t)) return; e = t.target } else e = t; if (!s(e)) return f(e, a.linkDisableSelector) ? l(e) : f(e, a.buttonDisableSelector) || f(e, a.formEnableSelector) ? o(e) : f(e, a.formSubmitSelector) ? i(e) : void 0 }; a.disableElement = function (t) { var o; o = t instanceof Event ? t.target : t; if (!s(o)) return f(o, a.linkDisableSelector) ? r(o) : f(o, a.buttonDisableSelector) || f(o, a.formDisableSelector) ? e(o) : f(o, a.formSubmitSelector) ? n(o) : void 0 }; r = function (t) { var e; if (!c(t, "ujs:disabled")) { e = t.getAttribute("data-disable-with"); if (null != e) { m(t, "ujs:enable-with", t.innerHTML); t.innerHTML = e } t.addEventListener("click", b); return m(t, "ujs:disabled", true) } }; l = function (t) { var e; e = c(t, "ujs:enable-with"); if (null != e) { t.innerHTML = e; m(t, "ujs:enable-with", null) } t.removeEventListener("click", b); return m(t, "ujs:disabled", null) }; n = function (t) { return u(t, a.formDisableSelector).forEach(e) }; e = function (t) { var e; if (!c(t, "ujs:disabled")) { e = t.getAttribute("data-disable-with"); if (null != e) if (f(t, "button")) { m(t, "ujs:enable-with", t.innerHTML); t.innerHTML = e } else { m(t, "ujs:enable-with", t.value); t.value = e } t.disabled = true; return m(t, "ujs:disabled", true) } }; i = function (t) { return u(t, a.formEnableSelector).forEach(o) }; o = function (t) { var e; e = c(t, "ujs:enable-with"); if (null != e) { f(t, "button") ? t.innerHTML = e : t.value = e; m(t, "ujs:enable-with", null) } t.disabled = false; return m(t, "ujs:disabled", null) }; d = function (t) { var e, n; n = null != (e = t.detail) ? e[0] : void 0; return null != (null != n ? n.getResponseHeader("X-Xhr-Redirect") : void 0) } }).call(this || t); (function () { var e, n; n = a.stopEverything; e = a.isContentEditable; a.handleMethod = function (r) { var o, i, l, u, c, s, d; s = this || t; d = s.getAttribute("data-method"); if (d && !e(this || t)) { c = a.href(s); i = a.csrfToken(); o = a.csrfParam(); l = document.createElement("form"); u = "<input name='_method' value='" + d + "' type='hidden' />"; null == o || null == i || a.isCrossDomain(c) || (u += "<input name='" + o + "' value='" + i + "' type='hidden' />"); u += '<input type="submit" />'; l.method = "post"; l.action = c; l.target = s.target; l.innerHTML = u; l.style.display = "none"; document.body.appendChild(l); l.querySelector('[type="submit"]').click(); return n(r) } } }).call(this || t); (function () { var e, n, r, o, i, l, u, c, s, d, f = [].slice; u = a.matches, r = a.getData, s = a.setData, n = a.fire, d = a.stopEverything, e = a.ajax, i = a.isCrossDomain, c = a.serializeElement, o = a.isContentEditable; l = function (t) { var e; e = t.getAttribute("data-remote"); return null != e && "false" !== e }; a.handleRemote = function (m) { var b, p, h, v, S, y, g; v = this || t; if (!l(v)) return true; if (!n(v, "ajax:before")) { n(v, "ajax:stopped"); return false } if (o(v)) { n(v, "ajax:stopped"); return false } g = v.getAttribute("data-with-credentials"); h = v.getAttribute("data-type") || "script"; if (u(v, a.formSubmitSelector)) { b = r(v, "ujs:submit-button"); S = r(v, "ujs:submit-button-formmethod") || v.method; y = r(v, "ujs:submit-button-formaction") || v.getAttribute("action") || location.href; "GET" === S.toUpperCase() && (y = y.replace(/\?.*$/, "")); if ("multipart/form-data" === v.enctype) { p = new FormData(v); null != b && p.append(b.name, b.value) } else p = c(v, b); s(v, "ujs:submit-button", null); s(v, "ujs:submit-button-formmethod", null); s(v, "ujs:submit-button-formaction", null) } else if (u(v, a.buttonClickSelector) || u(v, a.inputChangeSelector)) { S = v.getAttribute("data-method"); y = v.getAttribute("data-url"); p = c(v, v.getAttribute("data-params")) } else { S = v.getAttribute("data-method"); y = a.href(v); p = v.getAttribute("data-params") } e({ type: S || "GET", url: y, data: p, dataType: h, beforeSend: function (t, e) { if (n(v, "ajax:beforeSend", [t, e])) return n(v, "ajax:send", [t]); n(v, "ajax:stopped"); return false }, success: function () { var t; t = 1 <= arguments.length ? f.call(arguments, 0) : []; return n(v, "ajax:success", t) }, error: function () { var t; t = 1 <= arguments.length ? f.call(arguments, 0) : []; return n(v, "ajax:error", t) }, complete: function () { var t; t = 1 <= arguments.length ? f.call(arguments, 0) : []; return n(v, "ajax:complete", t) }, crossDomain: i(y), withCredentials: null != g && "false" !== g }); return d(m) }; a.formSubmitButtonClick = function (e) { var n, a; n = this || t; a = n.form; if (a) { n.name && s(a, "ujs:submit-button", { name: n.name, value: n.value }); s(a, "ujs:formnovalidate-button", n.formNoValidate); s(a, "ujs:submit-button-formaction", n.getAttribute("formaction")); return s(a, "ujs:submit-button-formmethod", n.getAttribute("formmethod")) } }; a.preventInsignificantClick = function (e) { var n, a, r, o, i, l; r = this || t; i = (r.getAttribute("data-method") || "GET").toUpperCase(); n = r.getAttribute("data-params"); o = e.metaKey || e.ctrlKey; a = o && "GET" === i && !n; l = null != e.button && 0 !== e.button; if (l || a) return e.stopImmediatePropagation() } }).call(this || t); (function () { var t, e, n, r, o, i, l, u, c, s, d, f, m, b, p; i = a.fire, n = a.delegate, u = a.getData, t = a.$, p = a.refreshCSRFTokens, e = a.CSRFProtection, m = a.loadCSPNonce, o = a.enableElement, r = a.disableElement, s = a.handleDisabledElement, c = a.handleConfirm, b = a.preventInsignificantClick, f = a.handleRemote, l = a.formSubmitButtonClick, d = a.handleMethod; if ("undefined" !== typeof jQuery && null !== jQuery && null != jQuery.ajax) { if (jQuery.rails) throw new Error("If you load both jquery_ujs and rails-ujs, use rails-ujs only."); jQuery.rails = a; jQuery.ajaxPrefilter((function (t, n, a) { if (!t.crossDomain) return e(a) })) } a.start = function () { if (window._rails_loaded) throw new Error("rails-ujs has already been loaded!"); window.addEventListener("pageshow", (function () { t(a.formEnableSelector).forEach((function (t) { if (u(t, "ujs:disabled")) return o(t) })); return t(a.linkDisableSelector).forEach((function (t) { if (u(t, "ujs:disabled")) return o(t) })) })); n(document, a.linkDisableSelector, "ajax:complete", o); n(document, a.linkDisableSelector, "ajax:stopped", o); n(document, a.buttonDisableSelector, "ajax:complete", o); n(document, a.buttonDisableSelector, "ajax:stopped", o); n(document, a.linkClickSelector, "click", b); n(document, a.linkClickSelector, "click", s); n(document, a.linkClickSelector, "click", c); n(document, a.linkClickSelector, "click", r); n(document, a.linkClickSelector, "click", f); n(document, a.linkClickSelector, "click", d); n(document, a.buttonClickSelector, "click", b); n(document, a.buttonClickSelector, "click", s); n(document, a.buttonClickSelector, "click", c); n(document, a.buttonClickSelector, "click", r); n(document, a.buttonClickSelector, "click", f); n(document, a.inputChangeSelector, "change", s); n(document, a.inputChangeSelector, "change", c); n(document, a.inputChangeSelector, "change", f); n(document, a.formSubmitSelector, "submit", s); n(document, a.formSubmitSelector, "submit", c); n(document, a.formSubmitSelector, "submit", f); n(document, a.formSubmitSelector, "submit", (function (t) { return setTimeout((function () { return r(t) }), 13) })); n(document, a.formSubmitSelector, "ajax:send", r); n(document, a.formSubmitSelector, "ajax:complete", o); n(document, a.formInputClickSelector, "click", b); n(document, a.formInputClickSelector, "click", s); n(document, a.formInputClickSelector, "click", c); n(document, a.formInputClickSelector, "click", l); $(document).on("DOMContentLoaded", p); $(document).on("DOMContentLoaded", m); return window._rails_loaded = true }; window.Rails === a && i(document, "rails:attachBindings") && a.start() }).call(this || t) }).call(this || t); e && (e = a) }).call(e); var n = e; export { n as default };

