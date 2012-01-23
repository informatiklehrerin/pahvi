

models = NS "Pahvi.models"
views = NS "Pahvi.views"
helpers = NS "Pahvi.helpers"


class models.Boxes extends Backbone.Collection

  constructor: (opts) ->
    {@typeMapping} = opts
    {@id} = opts
    delete opts.typeMapping
    delete opts.id
    super

    @bind "add", => @save()


  comparator: (box) ->
    -1 * parseInt box.get "zIndex"

  getView: (type) ->
    @typeMapping[type].View

  getModel: (type) ->
    @typeMapping[type].Model

  loadBoxes: (cb) ->
    for id, json_s of localStorage
      ob = JSON.parse json_s
      if ob.type
        Model = @getModel ob.type
        boxModel = new Model ob
        @add boxModel
    cb()

  isUnique: (attr, value) ->
    not @find (box) -> box.get(attr) is value

  makeUniqueName: (proposedName) ->

    name = proposedName
    i = 0

    while not @isUnique "name", name
      i += 1
      name = "#{ proposedName } #{ i }."

    return name

  createBox: (type, options={}) ->
    if not @typeMapping[type]
      return alert "Unkown type #{ type }!"

    {Model} = @typeMapping[type]

    if not options?.name
      options.name = Model::defaults.name

    options.name = @makeUniqueName options.name

    options.id = helpers.generateGUID()
    boxModel = new Model options
    @add boxModel


  save: ->


class LocalStore extends Backbone.Model

  constructor: ->
    super
    @set type: @type

  destroy: ->
    console.log "Not implemented"

  update: (changedAttributes) ->
    console.log "method: update. set attributes to model"
    @alreadySaved = changedAttributes
    @set changedAttributes


  open: (cb) ->
    @bind "change", =>
      console.log "method: open, model change"
      if not _.isEqual @changedAttributes(), @alreadySaved
        console.log "not already saved -> send to sharejs"
        @send @changedAttributes()
        @aleardySave = null
      else
        console.log "Attributes has already saved!"


    sharejs.open @get('name'), 'json', (err, doc) =>
      console.log "Open new doc: " + @get('name')
      @doc = doc
      if @doc.snapshot == null
        @doc.submitOp([{p:[], od:null, oi:{}}])
      else
        console.log "Set/update attributes from sharejs"
        @update @doc.snapshot

      @doc.on 'remoteop', (op) =>
        console.log "event: remoteop, model change: " + @get('name')
        if op[0]["p"].length == 0
          console.log "update all attributes"
          @update @doc.snapshot
        else
          new_attributes = {}
          for o in op
            attr = o["p"][0]
            new_attributes[o["p"][0]] = @doc.snapshot[attr]
          console.log "update special attributes"
          @update new_attributes
      cb err

  send: (attributes) ->
    console.log "method: send"
    submitOpValue = []
    for key, value of attributes
      submitOpValue.push { p:[key], od:null, oi:value }
    @doc.submitOp(submitOpValue)


class models.Settings extends Backbone.Model
  defaults:
    mode: "edit"
    hover: null


class BaseBoxModel extends LocalStore

  constructor: ->
    super
    @set type: @type



class models.TextBoxModel extends BaseBoxModel

  type: "text"

  configs: [
    "NameEditor",
    "TextColor",
    "BackgroundColor",
    "FontSize",
    "Border"
  ]

  defaults:
    name: "Text Box"
    top: "100px"
    left: "100px"
    zIndex: 100
    text: "<p>TextBox sample content</p>"
    "backgroundColor": "white"



class models.PlainBoxModel extends BaseBoxModel

  type: "plain"

  configs: [
    "NameEditor",
    "BackgroundColor",
    "Border"
  ]

  defaults:
    name: "Plain Box"
    top: "100px"
    left: "100px"
    zIndex: 100
    "backgroundColor": "white"


class models.ImageBox extends BaseBoxModel

  type: "image"

  configs: [
    "NameEditor",
    "ImageSrc",
  ]

  defaults:
    name: "Image Box"
    top: "100px"
    left: "100px"
    zIndex: 100


