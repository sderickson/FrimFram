(function() {
  window.FrimFram = {
    isProduction: function() {
      return window.location.href.indexOf('localhost') === -1;
    },
    wrapBackboneRequestCallbacks: function(options) {
      var originalOptions;
      if (options == null) {
        options = {};
      }
      originalOptions = _.clone(options);
      options.success = function(model) {
        model.dataState = 'standby';
        return typeof originalOptions.success === "function" ? originalOptions.success.apply(originalOptions, arguments) : void 0;
      };
      options.error = function(model) {
        model.dataState = 'standby';
        return typeof originalOptions.error === "function" ? originalOptions.error.apply(originalOptions, arguments) : void 0;
      };
      options.complete = function(model) {
        model.dataState = 'standby';
        return typeof originalOptions.complete === "function" ? originalOptions.complete.apply(originalOptions, arguments) : void 0;
      };
      return options;
    }
  };

}).call(this);
;(function() {
  var BaseClass;

  BaseClass = (function() {
    function BaseClass() {}

    BaseClass.prototype.superMerge = function(propertyName) {
      var combined, obj, value;
      combined = {};
      obj = this;
      while (obj) {
        value = obj != null ? obj[propertyName] : void 0;
        _.defaults(combined, value);
        obj = obj.__proto__ || Object.getPrototypeOf(obj);
      }
      return combined;
    };

    BaseClass.prototype.listenToShortcuts = function() {
      var func, shortcut, shortcuts, _results;
      shortcuts = this.superMerge('shortcuts');
      if (this.scope) {
        this.stopListeningToShortcuts();
      } else {
        this.scope = _.uniqueId('class-scope-');
      }
      _results = [];
      for (shortcut in shortcuts) {
        func = shortcuts[shortcut];
        if (!_.isFunction(func)) {
          func = this[func];
        }
        if (!func) {
          continue;
        }
        _results.push(key(shortcut, this.scope, _.bind(func, this)));
      }
      return _results;
    };

    BaseClass.prototype.stopListeningToShortcuts = function() {
      return key.deleteScope(this.scope);
    };

    BaseClass.prototype.destroy = function() {
      var key;
      this.off();
      this.stopListeningToShortcuts();
      for (key in this) {
        delete this[key];
      }
      this.destroyed = true;
      return this.destroy = _.noop;
    };

    return BaseClass;

  })();

  _.extend(BaseClass.prototype, Backbone.Events);

  FrimFram.BaseClass = BaseClass;

}).call(this);
;(function() {
  var View,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __slice = [].slice;

  View = (function(_super) {
    __extends(View, _super);

    View.prototype.template = '';

    View.prototype.shortcuts = {};

    View.globalContext = {
      'moment': window.moment
    };

    View.extendGlobalContext = function(globals) {
      return this.globalContext = _.extend(this.globalContext, globals);
    };

    function View(options) {
      this.events = this.superMerge('events');
      this.subviews = {};
      this.listenToShortcuts();
      View.__super__.constructor.apply(this, arguments);
    }

    View.prototype.render = function() {
      var id, view, _ref;
      _ref = this.subviews;
      for (id in _ref) {
        view = _ref[id];
        view.destroy();
      }
      this.subviews = {};
      this.$el.html(this.getTemplateResult());
      return this.onRender();
    };

    View.prototype.renderSelectors = function() {
      var newTemplate, selector, selectors, _i, _len, _results;
      selectors = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      newTemplate = $('<div>' + this.getTemplateResult() + '</div>');
      _results = [];
      for (_i = 0, _len = selectors.length; _i < _len; _i++) {
        selector = selectors[_i];
        _results.push(this.$el.find(selector).replaceWith(newTemplate.find(selector)));
      }
      return _results;
    };

    View.prototype.getTemplateResult = function() {
      if (_.isString(this.template)) {
        return this.template;
      } else {
        return this.template(this.getContext());
      }
    };

    View.prototype.initContext = function(pickPredicate) {
      var context;
      context = {};
      context.pathname = document.location.pathname;
      context = _.defaults(context, View.globalContext);
      if (pickPredicate) {
        context = _.extend(context, _.pick(this, pickPredicate, this));
      }
      return context;
    };

    View.prototype.getContext = function() {
      return this.initContext();
    };

    View.prototype.onRender = _.noop;

    View.prototype.onInsert = _.noop;

    View.prototype.listenToShortcuts = function(recurse) {
      var func, shortcut, shortcuts, view, viewID, _ref, _ref1, _results;
      shortcuts = this.superMerge('shortcuts');
      if (this.scope) {
        this.stopListeningToShortcuts();
      } else {
        this.scope = _.uniqueId('view-scope-');
      }
      _ref = this.shortcuts;
      for (shortcut in _ref) {
        func = _ref[shortcut];
        if (!_.isFunction(func)) {
          func = this[func];
        }
        if (!func) {
          continue;
        }
        key(shortcut, this.scope, _.bind(func, this));
      }
      if (recurse) {
        _ref1 = this.subviews;
        _results = [];
        for (viewID in _ref1) {
          view = _ref1[viewID];
          _results.push(view.listenToShortcuts(true));
        }
        return _results;
      }
    };

    View.prototype.stopListeningToShortcuts = function(recurse) {
      var view, viewID, _ref, _results;
      key.deleteScope(this.scope);
      if (recurse) {
        _ref = this.subviews;
        _results = [];
        for (viewID in _ref) {
          view = _ref[viewID];
          _results.push(view.stopListeningToShortcuts(true));
        }
        return _results;
      }
    };

    View.prototype.insertSubview = function(view, elToReplace) {
      var key, oldSubview;
      if (elToReplace == null) {
        elToReplace = null;
      }
      key = this.makeSubviewKey(view);
      oldSubview = this.subviews[key];
      if (elToReplace == null) {
        elToReplace = this.$el.find('#' + view.id);
      }
      if (!elToReplace.length) {
        throw new Error('Error inserting subview: do not have element for it to replace.');
      }
      elToReplace.after(view.el).remove();
      this.registerSubview(view, key);
      view.render();
      view.onInsert();
      if (oldSubview != null) {
        oldSubview.destroy();
      }
      return view;
    };

    View.prototype.registerSubview = function(view, key) {
      if (key == null) {
        key = this.makeSubviewKey(view);
      }
      this.subviews[key] = view;
      return view;
    };

    View.prototype.makeSubviewKey = function(view) {
      var key;
      key = view.id || (_.uniqueId(view.constructor.name));
      key = _.underscored(key);
      return key;
    };

    View.prototype.removeSubview = function(view) {
      var key, newEl;
      view.$el.empty();
      newEl = view.$el.clone();
      view.$el.replaceWith(newEl);
      key = _.findKey(this.subviews, function(v) {
        return v === view;
      });
      if (key) {
        delete this.subviews[key];
      }
      return view.destroy();
    };

    View.prototype.getQueryParam = function(param) {
      return View.getQueryParam(param);
    };

    View.getQueryParam = function(param) {
      var pair, pairs, query, _i, _len;
      query = this.getQueryString();
      pairs = (function() {
        var _i, _len, _ref, _results;
        _ref = query.split('&');
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          pair = _ref[_i];
          _results.push(pair.split('='));
        }
        return _results;
      })();
      for (_i = 0, _len = pairs.length; _i < _len; _i++) {
        pair = pairs[_i];
        if (pair[0] === param) {
          return decodeURIComponent(pair[1].replace(/\+/g, '%20'));
        }
      }
    };

    View.getQueryString = function() {
      return document.location.search.substring(1);
    };

    View.prototype.destroy = function() {
      var key, value, view, _i, _len, _ref;
      this.remove();
      this.stopListeningToShortcuts();
      _ref = _.values(this.subviews);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        view = _ref[_i];
        view.destroy();
      }
      for (key in this) {
        value = this[key];
        delete this[key];
      }
      this.destroyed = true;
      return this.destroy = _.noop;
    };

    return View;

  })(Backbone.View);

  _.defaults(View.prototype, FrimFram.BaseClass.prototype);

  FrimFram.View = FrimFram.BaseView = View;

}).call(this);
;(function() {
  var Application,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  Application = (function(_super) {
    __extends(Application, _super);

    Application.extend = Backbone.Model.extend;

    function Application() {
      this.preventBackspace = __bind(this.preventBackspace, this);
      this.watchForErrors();
      _.mixin(s.exports());
      $(document).bind('keydown', this.preventBackspace);
      this.handleNormalUrls();
      this.initialize.apply(this, arguments);
    }

    Application.prototype.initialize = _.noop;

    Application.prototype.start = function() {
      return Backbone.history.start({
        pushState: true
      });
    };

    Application.prototype.watchForErrors = function() {
      return window.addEventListener("error", function(e) {
        var alert;
        if ($('body').find('.runtime-error-alert').length) {
          return;
        }
        alert = $(FrimFram.runtimeErrorTemplate({
          errorMessage: e.error.message
        }));
        $('body').append(alert);
        alert.addClass('in');
        return alert.alert();
      });
    };

    Application.ctrlDefaultPrevented = [219, 221, 80, 83];

    Application.prototype.preventBackspace = function(event) {
      var _ref;
      if (event.keyCode === 8 && !this.elementAcceptsKeystrokes(event.srcElement || event.target)) {
        return event.preventDefault();
      } else if ((key.ctrl || key.command) && !key.alt && (_ref = event.keyCode, __indexOf.call(Application.ctrlDefaultPrevented, _ref) >= 0)) {
        return event.preventDefault();
      }
    };

    Application.prototype.elementAcceptsKeystrokes = function(el) {
      var tag, textInputTypes, type, _ref, _ref1;
      if (el == null) {
        el = document.activeElement;
      }
      tag = el.tagName.toLowerCase();
      type = (_ref = el.type) != null ? _ref.toLowerCase() : void 0;
      textInputTypes = ['text', 'password', 'file', 'number', 'search', 'url', 'tel', 'email', 'date', 'month', 'week', 'time', 'datetimelocal'];
      return (tag === 'textarea' || (tag === 'input' && __indexOf.call(textInputTypes, type) >= 0) || ((_ref1 = el.contentEditable) === '' || _ref1 === 'true')) && !(el.readOnly || el.disabled);
    };

    Application.prototype.handleNormalUrls = function() {
      return $(document).on('click', "a[href^='/']", function(event) {
        var href, passThrough, url;
        href = $(event.currentTarget).attr('href');
        passThrough = href.indexOf('sign_out') >= 0;
        if (!passThrough && !event.altKey && !event.ctrlKey && !event.metaKey && !event.shiftKey) {
          event.preventDefault();
          url = href.replace(/^\//, '').replace('\#\!\/', '');
          app.router.navigate(url, {
            trigger: true
          });
          return false;
        }
      });
    };

    return Application;

  })(FrimFram.BaseClass);

  FrimFram.Application = Application;

}).call(this);
;(function() {
  var Collection,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Collection = (function(_super) {
    __extends(Collection, _super);

    Collection.prototype.dataState = 'standby';

    function Collection(models, options) {
      Collection.__super__.constructor.call(this, models, options);
      if (options != null ? options.defaultFetchData : void 0) {
        this.defaultFetchData = options.defaultFetchData;
      }
    }

    Collection.prototype.fetch = function(options) {
      this.dataState = 'fetching';
      options = FrimFram.wrapBackboneRequestCallbacks(options);
      if (this.defaultFetchData) {
        if (options.data == null) {
          options.data = {};
        }
        _.defaults(options.data, this.defaultFetchData);
      }
      return Collection.__super__.fetch.call(this, options);
    };

    return Collection;

  })(Backbone.Collection);

  FrimFram.BaseCollection = FrimFram.Collection = Collection;

}).call(this);
;(function() {
  var ModalView,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  ModalView = (function(_super) {
    __extends(ModalView, _super);

    function ModalView() {
      return ModalView.__super__.constructor.apply(this, arguments);
    }

    ModalView.visibleModal = null;

    ModalView.prototype.className = 'modal fade';

    ModalView.prototype.destroyOnHidden = true;

    ModalView.prototype.onRender = function() {
      var modal;
      ModalView.__super__.onRender.call(this);
      modal = this;
      this.$el.on('show.bs.modal', function() {
        return modal.trigger('show');
      });
      this.$el.on('shown.bs.modal', function() {
        modal.onInsert();
        return modal.trigger('shown');
      });
      this.$el.on('hide.bs.modal', function() {
        return modal.trigger('hide');
      });
      this.$el.on('hidden.bs.modal', function() {
        return modal.onHidden();
      });
      return this.$el.on('loaded.bs.modal', function() {
        return modal.trigger('loaded');
      });
    };

    ModalView.prototype.hide = function(fast) {
      if (fast) {
        this.$el.removeClass('fade');
      }
      return this.$el.modal('hide');
    };

    ModalView.prototype.show = function(fast) {
      var _ref;
      if ((_ref = ModalView.visibleModal) != null) {
        _ref.hide(true);
      }
      this.render();
      if (fast) {
        this.$el.removeClass('fade');
      }
      $('body').append(this.$el);
      this.$el.modal('show');
      return ModalView.visibleModal = this;
    };

    ModalView.prototype.toggle = function() {
      return this.$el.modal('toggle');
    };

    ModalView.prototype.onHidden = function() {
      if (ModalView.visibleModal === this) {
        ModalView.visibleModal = null;
      }
      this.trigger('hidden');
      if (this.destroyOnHidden) {
        return this.destroy();
      }
    };

    return ModalView;

  })(FrimFram.View);

  FrimFram.ModalView = ModalView;

}).call(this);
;(function() {
  var Model,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Model = (function(_super) {
    __extends(Model, _super);

    Model.prototype.dataState = 'standby';

    Model.prototype.created = function() {
      return new Date(parseInt(this.id.substring(0, 8), 16) * 1000);
    };

    function Model(attributes, options) {
      Model.__super__.constructor.call(this, attributes, options);
      this.on('add', this.onAdded, this);
    }

    Model.prototype.onAdded = function() {
      return this.dataState = 'standby';
    };

    Model.prototype.schema = function() {
      var s;
      s = this.constructor.schema;
      if (_.isString(s)) {
        return tv4.getSchema(s);
      } else {
        return s;
      }
    };

    Model.prototype.onInvalid = function() {
      var error, _i, _len, _ref, _results;
      console.debug("Validation failed for " + (this.constructor.className || this) + ": '" + (this.get('name') || this) + "'.");
      _ref = this.validationError;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        error = _ref[_i];
        _results.push(console.debug("\t", error.dataPath, ':', error.message));
      }
      return _results;
    };

    Model.prototype.get = function(attr) {
      var parts, subKey, value, _i, _len;
      if (_(attr).contains('.')) {
        parts = attr.split('.');
        value = this.attributes;
        for (_i = 0, _len = parts.length; _i < _len; _i++) {
          subKey = parts[_i];
          if (_.isArray(value)) {
            subKey = parseInt(subKey);
          }
          value = value != null ? value[subKey] : void 0;
        }
        return value;
      } else {
        return Backbone.Model.prototype.get.apply(this, [attr]);
      }
    };

    Model.prototype.set = function(attributes, options) {
      var a, clone, key, parent, parts, slim, subKey, value, _i, _len;
      if ((this.dataState !== 'standby') && !(options.xhr || options.headers)) {
        throw new Error('Cannot set while fetching or saving.');
      }
      if (_.isString(attributes)) {
        a = {};
        a[attributes] = options;
        attributes = a;
        options = {};
      }
      for (key in attributes) {
        if (!_(key).contains('.')) {
          continue;
        }
        parts = key.split('.');
        slim = _.pick(this.attributes, parts[0]);
        clone = _.merge({}, slim);
        value = clone;
        for (_i = 0, _len = parts.length; _i < _len; _i++) {
          subKey = parts[_i];
          parent = value;
          if (_.isArray(value)) {
            subKey = parseInt(subKey);
          }
          value = value != null ? value[subKey] : void 0;
        }
        if (parent) {
          parent[subKey] = attributes[key];
          this.set(clone);
        }
        delete attributes[key];
      }
      Backbone.Model.prototype.set.apply(this, [attributes, options]);
      return Model.__super__.set.call(this, attributes, options);
    };

    Model.prototype.getValidationErrors = function() {
      var errors;
      errors = typeof tv4 !== "undefined" && tv4 !== null ? tv4.validateMultiple(this.attributes, this.constructor.schema || {}).errors : void 0;
      if (errors != null ? errors.length : void 0) {
        return errors;
      }
    };

    Model.prototype.validate = function() {
      return this.getValidationErrors();
    };

    Model.prototype.save = function(attrs, options) {
      var result;
      options = FrimFram.wrapBackboneRequestCallbacks(options);
      result = Model.__super__.save.call(this, attrs, options);
      if (result) {
        this.dataState = 'saving';
      }
      return result;
    };

    Model.prototype.fetch = function(options) {
      options = FrimFram.wrapBackboneRequestCallbacks(options);
      this.dataState = 'fetching';
      return Model.__super__.fetch.call(this, options);
    };

    return Model;

  })(Backbone.Model);

  FrimFram.BaseModel = FrimFram.Model = Model;

}).call(this);
;(function() {
  var RootView,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  RootView = (function(_super) {
    __extends(RootView, _super);

    function RootView() {
      return RootView.__super__.constructor.apply(this, arguments);
    }

    RootView.prototype.onInsert = function() {
      var title;
      RootView.__super__.onInsert.apply(this, arguments);
      title = _.result(this, 'title') || _.result(RootView, 'globalTitle') || this.constructor.name;
      return $('title').text(title);
    };

    RootView.prototype.title = _.noop;

    RootView.globalTitle = _.noop;

    RootView.prototype.onLeaveMessage = _.noop;

    return RootView;

  })(FrimFram.View);

  FrimFram.RootView = RootView;

}).call(this);
;(function() {
  var Router,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Router = (function(_super) {
    __extends(Router, _super);

    function Router() {
      return Router.__super__.constructor.apply(this, arguments);
    }

    Router.go = function(path) {
      return function() {
        return this.routeDirectly(path, arguments);
      };
    };

    Router.prototype.routeToServer = function() {
      return window.location.reload(true);
    };

    Router.prototype.routeDirectly = function(path, args) {
      var ViewClass, error, leavingMessage, view, _ref;
      if ((_ref = this.currentView) != null ? _ref.reloadOnClose : void 0) {
        return document.location.reload();
      }
      leavingMessage = _.result(this.currentView, 'onLeaveMessage');
      if (leavingMessage) {
        if (!confirm(leavingMessage)) {
          return this.navigate(this.currentPath, {
            replace: true
          });
        }
      }
      path = "views/" + path;
      try {
        ViewClass = require(path);
      } catch (_error) {
        error = _error;
        if (error.toString().search('Cannot find module "' + path + '" from') === -1) {
          throw error;
        }
      }
      if (ViewClass == null) {
        ViewClass = NotFoundView;
      }
      view = new ViewClass({
        params: args
      });
      return this.openView(view);
    };

    Router.prototype.openView = function(view) {
      this.closeCurrentView();
      view.render();
      $('body').empty().append(view.el);
      this.currentView = view;
      this.currentPath = document.location.pathname + document.location.search;
      return view.onInsert();
    };

    Router.prototype.closeCurrentView = function() {
      var _ref;
      return (_ref = this.currentView) != null ? _ref.destroy() : void 0;
    };

    Router.prototype.setupOnLeaveSite = function() {
      return window.addEventListener("beforeunload", (function(_this) {
        return function(e) {
          var leavingMessage;
          leavingMessage = _.result(_this.currentView, 'onLeaveMessage');
          if (leavingMessage) {
            e.returnValue = leavingMessage;
            return leavingMessage;
          }
        };
      })(this));
    };

    return Router;

  })(Backbone.Router);

  FrimFram.Router = Router;

}).call(this);
;(function() {
  FrimFram.onNetworkError = function() {
    var alert, jqxhr, r, s, _ref;
    jqxhr = _.find(arguments, function(arg) {
      return (arg.promise != null) && (arg.getResponseHeader != null);
    });
    r = jqxhr != null ? jqxhr.responseJSON : void 0;
    if ((jqxhr != null ? jqxhr.status : void 0) === 0) {
      s = 'Network failure';
    } else if (((_ref = arguments[2]) != null ? _ref.textStatus : void 0) === 'parsererror') {
      s = 'Backbone parser error';
    } else {
      s = (r != null ? r.message : void 0) || (r != null ? r.error : void 0) || 'Unknown error';
    }
    if (r) {
      console.error('Response JSON:', JSON.stringify(r, null, '\t'));
    } else {
      console.error('Error arguments:', arguments);
    }
    alert = $(FrimFram.runtimeErrorTemplate({
      errorMessage: s
    }));
    $('body').append(alert);
    alert.addClass('in');
    return alert.alert();
  };

  FrimFram.onAjaxError = FrimFram.onNetworkError;

  FrimFram.onModelError = FrimFram.onNetworkError;

  FrimFram.runtimeErrorTemplate = _.template("<div class=\"runtime-error-alert alert alert-danger fade\">\n  <button class=\"close\" type=\"button\" data-dismiss=\"alert\">\n    <span aria-hidden=\"true\">&times;</span>\n  </button>\n  <span><%= errorMessage %></span>\n</div>");

}).call(this);
;(function() {
  FrimFram.storage = {
    prefix: '-storage-',
    load: function(key) {
      var SyntaxError, s, value;
      s = localStorage.getItem(this.prefix + key);
      if (!s) {
        return null;
      }
      try {
        value = JSON.parse(s);
        return value;
      } catch (_error) {
        SyntaxError = _error;
        console.warn('error loading from storage', key);
        return null;
      }
    },
    save: function(key, value) {
      return localStorage.setItem(this.prefix + key, JSON.stringify(value));
    },
    remove: function(key) {
      return localStorage.removeItem(this.prefix + key);
    },
    clear: function() {
      var key, _results;
      _results = [];
      for (key in localStorage) {
        if (key.indexOf(this.prefix) === 0) {
          _results.push(localStorage.removeItem(key));
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    }
  };

}).call(this);
;
//# sourceMappingURL=/javascripts/frimfram.js.map