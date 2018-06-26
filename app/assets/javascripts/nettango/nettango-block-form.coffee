window.RactiveNetTangoBlockForm = EditForm.extend({
  data: () -> {
    spaceName:   undefined # String
    block:       undefined # Block
    blockNumber: undefined # Integer
    submitEvent: undefined # String
  }

  on: {

    'submit': (_) ->
      target = @get('target')
      target.fire(@get('submitEvent'), {}, @getBlock(), @get('blockNumber'))
      return

    'ntb-add-p-thing': (_, pType) ->
      num = @get("block.#{pType}.length")
      @push("block.#{pType}", @defaultParam(pType, num))
      return false

    '*.ntb-delete-p-thing': (_, pType, num) ->
      @splice("block.#{pType}", num, 1)
      return false

  }

  oninit: ->
    @_super()

  components: {
      formCheckbox:  RactiveEditFormCheckbox
    , formCode:      RactiveCodeContainerOneLine
    , formDropdown:  RactiveEditFormDropdown
    , spacer:        RactiveEditFormSpacer
    , labelledInput: RactiveLabelledInput
    , dropdown:      RactiveDropdown
    , parameter:     RactiveNetTangoParameter
  }

  defaultParam: (pType, num) -> {
      name: "#{pType}#{num}"
    , type: "num"
    , unit: undefined
    , def:  "10"
  }

  _setBlock: (sourceBlock) ->
    # Copy so we drop any uncommitted changes
    block = NetTangoBlockDefaults.copyBlock(sourceBlock)
    @set('block', block)
    return

  show: (target, spaceName, block, blockNumber, submitLabel, submitEvent) ->
    @_setBlock(block)
    @set('target', target)
    @set('spaceName', spaceName)
    @set('blockNumber', blockNumber)
    @set('submitLabel', submitLabel)
    @set('submitEvent', submitEvent)
    @fire('show-yourself')

  # this does something useful for widgets, but not for us, I think?
  genProps: (_) ->
    null

  getBlock: () ->
    blockValues = @get('block')
    block = { }
    # coffeelint: disable=max_line_length
    [ 'action', 'type', 'format', 'start', 'required', 'control', 'limit', 'blockColor', 'textColor', 'borderColor', 'fontWeight', 'fontSize', 'fontFace' ]
      .filter((f) -> blockValues.hasOwnProperty(f) and blockValues[f] isnt "")
      .forEach((f) -> block[f] = blockValues[f])
    # coffeelint: enable=max_line_length
    if blockValues.control
      block.clauses = if blockValues.type is 'nlogo:ifelse'
        [{ name: "else", action: "else", format: "" }]
      else
        []

    block.params     = @processPThings(blockValues.params)
    block.properties = @processPThings(blockValues.properties)

    block

  processPThings: (pThings) ->
    pCopies = for pValues in pThings
      pThing = { }
      [ 'name', 'unit', 'type' ].forEach((f) -> pThing[f] = pValues[f])
      # Using `default` as a property name gives Ractive some issues, so we "translate" it back here.
      pThing.default = pValues.def
      # User may have switched type a couple times, so only copy the properties if the type is appropriate to them
      if pValues.type is 'range'
        [ 'min', 'max', 'step' ].forEach((f) -> pThing[f] = pValues[f])
      else if pValues.type is 'select'
        pThing.values = pValues.valuesString.split(/\s*;\s*|\n/).filter((s) -> s isnt "")
      pThing

    pCopies

  partials: {

    title: "{{ spaceName }} Block"

    widgetFields:
      # coffeelint: disable=max_line_length
      """
      {{# block }}

      <labelledInput id="{{ id }}-name" name="name" type="text" value="{{ action }}" label="Display name" style="flex-grow: 1;" />

      <spacer height="15px" />

      <dropdown id="{{ id }}-type" name="{{ type }}" value="{{ type }}" label="Type"
        options="{{ [ 'nlogo:procedure', 'nlogo:command', 'nlogo:if', 'nlogo:ifelse', 'nlogo:ask' ] }}"
        />

      <spacer height="15px" />

      <labelledInput id="{{ id }}-format" name="format" type="text" value="{{ format }}" label="Code Format ({#} for param, {P#} for property)" style="flex-grow: 1;" />

      <div class="flex-row ntb-form-row" style="align-items: center;">
        <formCheckbox id="{{ id }}-start" isChecked={{ start }} labelText="Start Block" name="startblock" />
        <formCheckbox id="{{ id }}-control" isChecked={{ control }} labelText="Control Block" name="controlblock" />
        <labelledInput id="{{ id }}-limit" name="limit" type="number" value="{{ limit }}" label="Limit" style="flex-grow: 1;" />
      </div>

      <div class="flex-row ntb-form-row" style="align-items: center;">
        <labelledInput id="{{ id }}-f-weight" name="font-weight" type="number" value="{{ fontWeight }}" label="Font weight" style="flex-grow: 1;" />
        <labelledInput id="{{ id }}-f-size"   name="font-size"   type="number" value="{{ fontSize }}"   label="Font size"   style="flex-grow: 1;" />
        <labelledInput id="{{ id }}-f-face"   name="font-face"   type="text"   value="{{ fontFace }}"   label="Typeface"    style="flex-grow: 2;" />
      </div>

      <div class="flex-row ntb-form-row" style="align-items: center;">
        <labelledInput id="{{ id }}-block-color"  name="block-color"  type="color" value="{{ blockColor }}"  label="Block color"  style="flex-grow: 1;" twoway="true" />
        <labelledInput id="{{ id }}-text-color"   name="text-color"   type="color" value="{{ textColor }}"   label="Text color"   style="flex-grow: 1;" />
        <labelledInput id="{{ id }}-border-color" name="border-color" type="color" value="{{ borderColor }}" label="Border color" style="flex-grow: 1;" />
      </div>

      <div class="flex-column" >
        <div class="ntb-block-defs-controls">
          <label>Block Parameters</label>
          <button class="ntb-button" on-click="[ 'ntb-add-p-thing', 'params' ]">Add Parameter</button>
        </div>
        {{#params:number }}
          <parameter number="{{ number }}" p="{{ this }}" pType="params" />
        {{/params }}
      </div>

      <div class="flex-column" >
        <div class="ntb-block-defs-controls">
          <label>Block Properties</label>
          <button class="ntb-button" on-click="[ 'ntb-add-p-thing', 'properties' ]">Add Property</button>
        </div>
        {{#properties:number }}
          <parameter number="{{ number }}" p="{{ this }}" pType="properties" />
        {{/properties }}
      </div>

      {{/block }}
      """
      # coffeelint: enable=max_line_length
  }
})