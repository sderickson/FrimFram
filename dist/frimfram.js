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

    BaseClass.prototype.listenToShortcuts = function() {
      var func, ref, results, shortcut;
      if (!this.shortcuts) {
        return;
      }
      if (this.scope) {
        this.stopListeningToShortcuts();
      } else {
        this.scope = _.uniqueId('class-scope-');
      }
      ref = this.shortcuts;
      results = [];
      for (shortcut in ref) {
        func = ref[shortcut];
        if (!_.isFunction(func)) {
          func = this[func];
        }
        if (!func) {
          continue;
        }
        results.push(key(shortcut, this.scope, _.bind(func, this)));
      }
      return results;
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
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty,
    slice = [].slice;

  View = (function(superClass) {
    extend(View, superClass);

    View.prototype.template = '';

    View.prototype.shortcuts = {};

    View.globalContext = {
      'moment': window.moment
    };

    View.extendGlobalContext = function(globals) {
      return this.globalContext = _.extend(this.globalContext, globals);
    };

    function View(options) {
      this.subviews = {};
      this.listenToShortcuts();
      View.__super__.constructor.apply(this, arguments);
    }

    View.prototype.render = function() {
      var id, ref, view;
      ref = this.subviews;
      for (id in ref) {
        view = ref[id];
        view.destroy();
      }
      this.subviews = {};
      this.$el.html(this.getTemplateResult());
      return this.onRender();
    };

    View.prototype.renderSelectors = function() {
      var elPair, i, j, len, newTemplate, results, selector, selectors;
      selectors = 1 <= arguments.length ? slice.call(arguments, 0) : [];
      newTemplate = $('<div>' + this.getTemplateResult() + '</div>');
      results = [];
      for (i = j = 0, len = selectors.length; j < len; i = ++j) {
        selector = selectors[i];
        results.push((function() {
          var k, len1, ref, results1;
          ref = _.zip(this.$el.find(selector), newTemplate.find(selector));
          results1 = [];
          for (k = 0, len1 = ref.length; k < len1; k++) {
            elPair = ref[k];
            results1.push($(elPair[0]).replaceWith($(elPair[1])));
          }
          return results1;
        }).call(this));
      }
      return results;
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
      var func, ref, ref1, results, shortcut, view, viewID;
      if (!this.shortcuts) {
        return;
      }
      if (this.scope) {
        this.stopListeningToShortcuts();
      } else {
        this.scope = _.uniqueId('view-scope-');
      }
      ref = this.shortcuts;
      for (shortcut in ref) {
        func = ref[shortcut];
        if (!_.isFunction(func)) {
          func = this[func];
        }
        if (!func) {
          continue;
        }
        key(shortcut, this.scope, _.bind(func, this));
      }
      if (recurse) {
        ref1 = this.subviews;
        results = [];
        for (viewID in ref1) {
          view = ref1[viewID];
          results.push(view.listenToShortcuts(true));
        }
        return results;
      }
    };

    View.prototype.stopListeningToShortcuts = function(recurse) {
      var ref, results, view, viewID;
      key.deleteScope(this.scope);
      if (recurse) {
        ref = this.subviews;
        results = [];
        for (viewID in ref) {
          view = ref[viewID];
          results.push(view.stopListeningToShortcuts(true));
        }
        return results;
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
      key = _.snakeCase(key);
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
      var j, len, pair, pairs, query;
      query = this.getQueryString();
      pairs = (function() {
        var j, len, ref, results;
        ref = query.split('&');
        results = [];
        for (j = 0, len = ref.length; j < len; j++) {
          pair = ref[j];
          results.push(pair.split('='));
        }
        return results;
      })();
      for (j = 0, len = pairs.length; j < len; j++) {
        pair = pairs[j];
        if (pair[0] === param) {
          return decodeURIComponent(pair[1].replace(/\+/g, '%20'));
        }
      }
    };

    View.getQueryString = function() {
      return document.location.search.substring(1);
    };

    View.prototype.destroy = function() {
      var j, key, len, ref, value, view;
      this.remove();
      this.stopListeningToShortcuts();
      ref = _.values(this.subviews);
      for (j = 0, len = ref.length; j < len; j++) {
        view = ref[j];
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
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty,
    indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  Application = (function(superClass) {
    extend(Application, superClass);

    Application.extend = Backbone.Model.extend;

    function Application() {
      this.preventBackspace = bind(this.preventBackspace, this);
      this.watchForErrors();
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
      var ref;
      if (event.keyCode === 8 && !this.elementAcceptsKeystrokes(event.srcElement || event.target)) {
        return event.preventDefault();
      } else if ((key.ctrl || key.command) && !key.alt && (ref = event.keyCode, indexOf.call(Application.ctrlDefaultPrevented, ref) >= 0)) {
        return event.preventDefault();
      }
    };

    Application.prototype.elementAcceptsKeystrokes = function(el) {
      var ref, ref1, tag, textInputTypes, type;
      if (el == null) {
        el = document.activeElement;
      }
      tag = el.tagName.toLowerCase();
      type = (ref = el.type) != null ? ref.toLowerCase() : void 0;
      textInputTypes = ['text', 'password', 'file', 'number', 'search', 'url', 'tel', 'email', 'date', 'month', 'week', 'time', 'datetimelocal'];
      return (tag === 'textarea' || (tag === 'input' && indexOf.call(textInputTypes, type) >= 0) || ((ref1 = el.contentEditable) === '' || ref1 === 'true')) && !(el.readOnly || el.disabled);
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
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  Collection = (function(superClass) {
    extend(Collection, superClass);

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
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  ModalView = (function(superClass) {
    extend(ModalView, superClass);

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
      var ref;
      if ((ref = ModalView.visibleModal) != null) {
        ref.hide(true);
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
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  Model = (function(superClass) {
    extend(Model, superClass);

    function Model(attributes, options) {
      Model.__super__.constructor.call(this, attributes, options);
      this.on('add', this.onAdded, this);
      this.on('invalid', this.onInvalid, this);
    }

    Model.prototype.dataState = 'standby';

    Model.prototype.created = function() {
      return new Date(parseInt(this.id.substring(0, 8), 16) * 1000);
    };

    Model.prototype.onAdded = function() {
      return this.dataState = 'standby';
    };

    Model.prototype.schema = function() {
      var ref, s;
      s = this.constructor.schema;
      if (_.isString(s)) {
        return (ref = app.ajv.getSchema(s)) != null ? ref.schema : void 0;
      } else {
        return s;
      }
    };

    Model.prototype.onInvalid = function() {
      var error, i, len, ref, results;
      console.debug("Validation failed for " + (this.constructor.className || this) + ": '" + (this.get('name') || this) + "'.");
      ref = this.validationError;
      results = [];
      for (i = 0, len = ref.length; i < len; i++) {
        error = ref[i];
        results.push(console.debug("\t", error.dataPath, ':', error.message));
      }
      return results;
    };

    Model.prototype.set = function(attributes, options) {
      if ((this.dataState !== 'standby') && !(options.xhr || options.headers)) {
        throw new Error('Cannot set while fetching or saving.');
      }
      return Model.__super__.set.call(this, attributes, options);
    };

    Model.prototype.getValidationErrors = function() {
      var valid;
      valid = app.ajv.validate(this.constructor.schema || {}, this.attributes);
      if (!valid) {
        return app.ajv.errors;
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
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  RootView = (function(superClass) {
    extend(RootView, superClass);

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
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  Router = (function(superClass) {
    extend(Router, superClass);

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
      var ViewClass, error, error1, leavingMessage, ref, view;
      if ((ref = this.currentView) != null ? ref.reloadOnClose : void 0) {
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
      } catch (error1) {
        error = error1;
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
      var ref;
      return (ref = this.currentView) != null ? ref.destroy() : void 0;
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
    var alert, jqxhr, r, ref, s;
    jqxhr = _.find(arguments, function(arg) {
      return (arg.promise != null) && (arg.getResponseHeader != null);
    });
    r = jqxhr != null ? jqxhr.responseJSON : void 0;
    if ((jqxhr != null ? jqxhr.status : void 0) === 0) {
      s = 'Network failure';
    } else if (((ref = arguments[2]) != null ? ref.textStatus : void 0) === 'parsererror') {
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
      var SyntaxError, error, s, value;
      s = localStorage.getItem(this.prefix + key);
      if (!s) {
        return null;
      }
      try {
        value = JSON.parse(s);
        return value;
      } catch (error) {
        SyntaxError = error;
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
      var key, results;
      results = [];
      for (key in localStorage) {
        if (key.indexOf(this.prefix) === 0) {
          results.push(localStorage.removeItem(key));
        } else {
          results.push(void 0);
        }
      }
      return results;
    }
  };

}).call(this);
;
//# sourceMappingURL=/javascripts/frimfram.js.map