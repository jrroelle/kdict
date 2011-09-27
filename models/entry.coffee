ktools = require("../public/javascripts/korean.js")

# TODO: Abstract this validation out to a seperate module to be used in interface
#       code
valHangul = (value) ->
  return ktools.detect_characters(value) == 'hangul'

valAlphanumeric = (value) ->
  return ktools.detect_characters(value) == 'english'

valHanja = (value) ->
  return ktools.detect_characters(value) == 'hanja'

valPOS = (value) ->
  true

cleanSpaces = (value) ->
  console.log "Cleaning spaces"
  console.log value
  return value.replace(/^\s+|\s+$/g, '')


defineModel = (mongoose, fn) ->
  Schema = mongoose.Schema

  # Bundles up all data for a single 'meaning' thinking from the Korean perspective
  Sense = new Schema(
    hanja: [
      type: String
      validate: [ valHanja, "Hanja must only contain Chinese (Hanja) characters" ]
      index: true
      set: cleanSpaces
    ]
    pos:
      type: String
      validate: [ valPOS, "POS must be one of a list of approved part of speech tags" ]

    definitions:
      english: [
        type: String
        validate: [ valAlphanumeric, "English must only contain alphanumeric characters" ]
        index: true
      ]
    related:
      type: [ String ]
      # TODO Optional
      #validate: [ valHangul, "Related words must only contain Hangul characters" ]

    legacy:
      submitter: String
      table:     String
      wordid:    Number
  )
  Sense.virtual("id").get ->
    @_id.toHexString()

  Sense.path('hanja').set (list) ->
    out_list = []
    for val in list
      out_list.push val.replace(/^\s+|\s+$/g, '')
    return out_list

  Sense.path('definitions.english').set (list) ->
    out_list = []
    for val in list
      out_list.push val.replace(/^\s+|\s+$/g, '')
    return out_list

  Sense.virtual("definitions.english_all").get ->
    console.log @definitions.english
    @definitions.english.join('; ')

  Sense.virtual("definitions.english_all").set (list) ->
    # TODO What about removing whitespace and all that junk
    console.log "List:"
    console.log list
    if list
      @definitions.english = list.split(';')

  Sense.virtual("hanja_all").get ->
    @hanja.join('; ')
  Sense.virtual("hanja_all").set (list) ->
    # TODO What about removing whitespace and all that junk
    if list
      @hanja = list.split(';')



  Entry = new Schema(
    korean:
      hangul:
        type: String
        required: true
        index:
          unique: true
        validate: [ valHangul, "Korean must not contain English characters" ]
        set: cleanSpaces

      length: # But what about the fact that JS has a length function
        type: Number
        required: true
        index: true
      # TODO Phonetic stuff
      # TODO: mr: { type: String, index: false, validate: [ valAlphabet, 'McCune-Reischauer must only contain alphabetic characters' },
      # TODO: yale: { type: String, index: false, validate: [ valAlphabet, 'Yale must only contain alphabetic characters' },
      # TODO: rr: { type: String, index: false, validate: [ valAlphabet, 'Revised Romanization must only contain alphabetic characters' },
      # TODO: ipa: { type: String, index: false, validate: [ valIPA, 'IPA must only contain IPA characters' },
      # TODO: simplified // our hacky thing

    senses: [ Sense ]

    # More general-use, users able to set
    tags: [
      type:   Schema.ObjectId
      index:  true
      ref:    "Tag"
    ]

    # NEW: Not sure if this is overkill on data duplication
    updates: [
      type: Schema.ObjectId
      #index: true
      ref:  "Update"
    ]
  )

  Entry.virtual("id").get ->
    @_id.toHexString()

  Entry.pre "save", (next) ->
    # TODO Automatically generate phonetic representation
    # TODO Automatically create Update
    # TODO Increment revision count
    console.log "korean"
    console.log @korean
    @korean.hangul['length'] = @korean.hangul.length
    next()

  mongoose.model "Entry", Entry
  fn()

exports.defineModel = defineModel
