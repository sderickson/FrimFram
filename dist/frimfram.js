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
  var BaseView,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __slice = [].slice;

  BaseView = (function(_super) {
    __extends(BaseView, _super);

    BaseView.prototype.template = '';

    BaseView.prototype.shortcuts = {};

    BaseView.globalContext = {
      'moment': window.moment
    };

    BaseView.extendGlobalContext = function(globals) {
      return this.globalContext = _.extend(this.globalContext, globals);
    };

    function BaseView(options) {
      this.events = this.superMerge('events');
      this.subviews = {};
      this.listenToShortcuts();
      BaseView.__super__.constructor.apply(this, arguments);
    }

    BaseView.prototype.render = function() {
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

    BaseView.prototype.renderSelectors = function() {
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

    BaseView.prototype.getTemplateResult = function() {
      if (_.isString(this.template)) {
        return this.template;
      } else {
        return this.template(this.getContext());
      }
    };

    BaseView.prototype.initContext = function(pickPredicate) {
      var context;
      context = {};
      context.pathname = document.location.pathname;
      context = _.defaults(context, BaseView.globalContext);
      if (pickPredicate) {
        context = _.extend(context, _.pick(this, pickPredicate, this));
      }
      return context;
    };

    BaseView.prototype.getContext = function() {
      return this.initContext();
    };

    BaseView.prototype.onRender = _.noop;

    BaseView.prototype.onInsert = _.noop;

    BaseView.prototype.listenToShortcuts = function(recurse) {
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

    BaseView.prototype.stopListeningToShortcuts = function(recurse) {
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

    BaseView.prototype.insertSubview = function(view, elToReplace) {
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

    BaseView.prototype.registerSubview = function(view, key) {
      if (key == null) {
        key = this.makeSubviewKey(view);
      }
      this.subviews[key] = view;
      return view;
    };

    BaseView.prototype.makeSubviewKey = function(view) {
      var key;
      key = view.id || (_.uniqueId(view.constructor.name));
      key = _.underscored(key);
      return key;
    };

    BaseView.prototype.removeSubview = function(view) {
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

    BaseView.prototype.getQueryParam = function(param) {
      return BaseView.getQueryParam(param);
    };

    BaseView.getQueryParam = function(param) {
      var pair, pairs, query, _i, _len, _ref;
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
          return (_ref = {
            'true': true,
            'false': false
          }[pair[1]]) != null ? _ref : decodeURIComponent(pair[1]);
        }
      }
    };

    BaseView.getQueryString = function() {
      return document.location.search.substring(1);
    };

    BaseView.prototype.destroy = function() {
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

    return BaseView;

  })(Backbone.View);

  _.defaults(BaseView.prototype, FrimFram.BaseClass.prototype);

  FrimFram.BaseView = BaseView;

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
      return window.onerror = function(msg, url, line, col, error) {
        var alert, close;
        if ($('body').find('.runtime-error-alert').length) {
          return;
        }
        alert = $(FrimFram.runtimeErrorTemplate({
          errorMessage: msg
        }));
        $('body').append(alert);
        alert.addClass('in');
        alert.alert();
        return close = function() {
          return alert.alert('close');
        };
      };
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
  var BaseCollection,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  BaseCollection = (function(_super) {
    __extends(BaseCollection, _super);

    BaseCollection.prototype.dataState = 'standby';

    function BaseCollection(models, options) {
      BaseCollection.__super__.constructor.call(this, models, options);
      if (options != null ? options.defaultFetchData : void 0) {
        this.defaultFetchData = options.defaultFetchData;
      }
    }

    BaseCollection.prototype.fetch = function(options) {
      this.dataState = 'fetching';
      options = FrimFram.wrapBackboneRequestCallbacks(options);
      if (this.defaultFetchData) {
        if (options.data == null) {
          options.data = {};
        }
        _.defaults(options.data, this.defaultFetchData);
      }
      return BaseCollection.__super__.fetch.call(this, options);
    };

    return BaseCollection;

  })(Backbone.Collection);

  FrimFram.BaseCollection = BaseCollection;

}).call(this);
;(function() {
  var BaseModel,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  BaseModel = (function(_super) {
    __extends(BaseModel, _super);

    BaseModel.prototype.dataState = 'standby';

    function BaseModel(attributes, options) {
      BaseModel.__super__.constructor.call(this, attributes, options);
      this.on('add', this.onAdded, this);
    }

    BaseModel.prototype.onAdded = function() {
      return this.dataState = 'standby';
    };

    BaseModel.prototype.schema = function() {
      var s;
      s = this.constructor.schema;
      if (_.isString(s)) {
        return tv4.getSchema(s);
      } else {
        return s;
      }
    };

    BaseModel.prototype.onInvalid = function() {
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

    BaseModel.prototype.get = function(attr) {
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

    BaseModel.prototype.set = function(attributes, options) {
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
      return BaseModel.__super__.set.call(this, attributes, options);
    };

    BaseModel.prototype.getValidationErrors = function() {
      var errors;
      errors = typeof tv4 !== "undefined" && tv4 !== null ? tv4.validateMultiple(this.attributes, this.constructor.schema || {}).errors : void 0;
      if (errors != null ? errors.length : void 0) {
        return errors;
      }
    };

    BaseModel.prototype.validate = function() {
      return this.getValidationErrors();
    };

    BaseModel.prototype.save = function(attrs, options) {
      var result;
      options = FrimFram.wrapBackboneRequestCallbacks(options);
      result = BaseModel.__super__.save.call(this, attrs, options);
      if (result) {
        this.dataState = 'saving';
      }
      return result;
    };

    BaseModel.prototype.fetch = function(options) {
      options = FrimFram.wrapBackboneRequestCallbacks(options);
      this.dataState = 'fetching';
      return BaseModel.__super__.fetch.call(this, options);
    };

    return BaseModel;

  })(Backbone.Model);

  FrimFram.BaseModel = BaseModel;

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

  })(FrimFram.BaseView);

  FrimFram.ModalView = ModalView;

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
      title = _.result(this, 'title') || this.constructor.name;
      return $('title').text(title);
    };

    RootView.prototype.title = _.noop;

    return RootView;

  })(FrimFram.BaseView);

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
      var ViewClass, error, view, _ref;
      if ((_ref = this.currentView) != null ? _ref.reloadOnClose : void 0) {
        return document.location.reload();
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
      return view.onInsert();
    };

    Router.prototype.closeCurrentView = function() {
      var _ref;
      return (_ref = this.currentView) != null ? _ref.destroy() : void 0;
    };

    return Router;

  })(Backbone.Router);

  FrimFram.Router = Router;

}).call(this);
;(function() {
  FrimFram.onModelError = function(model, jqxhr) {
    return FrimFram.onAjaxError(jqxhr);
  };

  FrimFram.onAjaxError = function(jqxhr) {
    var alert, close, r, s;
    r = jqxhr.responseJSON;
    console.log(r || jqxhr.responseText);
    if (r == null) {
      r = {};
    }
    s = "Response error " + r.error + " (" + r.statusCode + "): " + r.message;
    alert = $(FrimFram.runtimeErrorTemplate({
      errorMessage: s
    }));
    $('body').append(alert);
    alert.addClass('in');
    alert.alert();
    return close = function() {
      return alert.alert('close');
    };
  };

  FrimFram.runtimeErrorTemplate = _.template("<div class=\"runtime-error-alert alert alert-danger fade\">\n  <button class=\"close\" type=\"button\" data-dismiss=\"alert\">\n    <span aria-hidden=\"true\">&times;</span>\n  </button>\n  <strong class=\"spr\">Runtime Error:</strong>\n  <span><%= errorMessage %></span>\n  <br/>\n  <span class=\"pull-right text-muted\">See console for more info.</span>\n</div>");

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