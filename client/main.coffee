

views = NS "Pahvi.views"
models = NS "Pahvi.models"
helpers = NS "Pahvi.helpers"

# Create model/view/configure mapping of available Box types.  Box Models,
# Views and Configure views are connected together by their `type` property.
# This will go through those and creates `Boxes.types` mapping for them.
# Later this can be used to get corresponding View/Model/CongigureView
typeMapping = {}
typeSources =
  Model: models
  View: views
for metaClassName, namespace of typeSources
  for __, metaClass of namespace when metaClass.prototype?.type
    typeMapping[metaClass.prototype.type] ?= {}
    typeMapping[metaClass.prototype.type][metaClassName] = metaClass


class Workspace extends Backbone.Router

  constructor: ({@settings, @collection}) ->
    super

    @settings.bind "change:mode", =>
      @navigate @settings.get "mode"

    @collection.bind "change:name", (box) =>
      if box.id is  @settings.get "activeBox"
        @navigate "#{ @settings.get "mode" }/#{ box.get "name" }"

    @settings.bind "change:activeBox", =>
      if boxId = @settings.get "activeBox"
        box = @collection.get boxId
        @navigate "#{ @settings.get "mode" }/#{ box.get "name" }"
      else
        @navigate "#{ @settings.get "mode" }"

  routes:
    "": "welcome"
    "/": "welcome"
    "presentation": "presentation"
    "presentation/:name": "presentation"
    "edit": "edit"
    "edit/:name": "edit"


  welcome: ->
    views.showMessage "Welcome to Pahvi!"


  for mode in ["presentation", "edit"] then do (mode) ->
    Workspace::[mode] = (boxName) ->
      @settings.set mode: mode

      if boxName
        box = @collection.find (box) -> box.get("name") is unescape boxName

      if box
        @settings.set activeBox: box.id
      else
        @settings.set activeBox: null
        helpers.zoomOut()

$ ->


  settings = new models.Settings
    id: "settings"

  boxes = new models.Boxes [],
    id: window.location.pathname[1..-1] or "_default"
    typeMapping: typeMapping



  menu = new views.Menu
    el: ".menu"
    settings: settings

  menu.render()


  board = new views.Cardboard
    el: ".pahvi"
    settings: settings
    collection: boxes

  board.render()



  sidemenu = new views.SideMenu
    el: ".mediamenu"
    collection: boxes
    settings: settings

  sidemenu.render()

  boxes.open (err) ->
    throw err if err
    router = new Workspace
      settings: settings
      collection: boxes
    Backbone.history.start()
    settings.set activeBox: null


