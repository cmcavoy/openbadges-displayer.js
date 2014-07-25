_ = require 'underscore'
path = require 'path'
insertCss = require 'insert-css'
fs = require 'fs'
PNGBaker = require '../vendor/png-baker.js'
tplfile = null
fs.readFile __dirname + '/modal.tpl', 'utf8', (err, data) ->
  if err
    throw err
  tplfile = _.template data
  console.log tplfile
css = fs.readFileSync __dirname + '/../../dist/openbadges-displayer.min.css'

class OpenBadgesDisplayer
  constructor: (options) ->
    @disable_debug()

    @init_lightbox()

    # If esc key is pressed, close the lightbox modal.
    window.addEventListener 'keydown', (e) =>
      console.log e
      if e.keyCode == 27
        @hideLightbox()

    @insert_css()
    @badges = []
    @load_images(options)
    @parse_meta_data()

  eneable_debug: () ->
    console.log = @old_logger

  disable_debug: () ->
    @old_logger = console.log
    console.log = () ->

  init_lightbox: () ->
    # create overlay
    @overlay = document.createElement 'div'
    @overlay.setAttribute 'class', 'ob-overlay'
    @overlay.addEventListener 'click', () =>
      @hideLightbox()
    @overlay.style.display = 'none'

    # create lightbox
    @lightbox = document.createElement 'div'
    @lightbox.setAttribute 'class', 'ob-lightbox container'
    @lightbox.setAttribute 'id', 'ob-lightbox'
    @lightbox.style.display = 'none'

    document.body.appendChild @overlay
    document.body.appendChild @lightbox

  insert_css: () ->
    console.log 'Inserting css'
    insertCss css

  load_images: (options) ->
    console.log 'Loading images'

    if typeof options is 'undefined'
      options = {}

    if options.id
      @images = [document.getElementById options.id]
    else if options.className
      @images = document.getElementsByClassName options.className
    else
      @images = document.getElementsByTagName 'img'

  parse_meta_data: () ->
    console.log 'Parsing meta data'
    xhr = null
    self = @

    for img in self.images
      self.parse_badge img

  parse_badge: (img) ->
    console.log 'Parse badge'

    xhr = new XMLHttpRequest()
    xhr.open 'GET', img.src, true
    xhr.responseType = 'arraybuffer'
    
    xhr.onload = () =>
      if xhr.status is 200
        try
          baked = new PNGBaker xhr.response

          # Strip non-ascii characters.
          # Using regex found here: http://stackoverflow.com/a/20856252
          assertion = JSON.parse baked.textChunks['openbadges'].replace(
            /[^A-Za-z 0-9 \.,\?""!@#\$%\^&\*\(\)-_=\+;:<>\/\\\|\}\{\[\]`~]*/g,
            ''
          )

          @badges.push {
            assertion : assertion
            img: img
          }

          @display_badge assertion, img

        catch error

    xhr.ontimeout = () -> console.error "The xhr request timed out."
    xhr.onerror = () -> console.log 'error getting badge data'

    xhr.send null

  display_badge: (assertion, img) ->
    console.log 'Display badge'

    badgeTitle = assertion.badge.name
    badgeInfo = assertion.badge.description
    height = 100

    newDiv = document.createElement 'div'
    newImg = document.createElement 'div'
    newImgWrapper = document.createElement 'div'
    newSpan = document.createElement 'span'
    newStrong = document.createElement 'strong'
    newP = document.createElement 'p'
    newA = document.createElement 'a'

    badgeID = 'badge_' + new Date().getTime().toString()
    newDiv.setAttribute 'class', 'open-badge-thumb'
    newDiv.setAttribute 'id', badgeID
    newImgWrapper.setAttribute 'class', 'ob-badge-logo-wrapper'
    newImg.setAttribute 'class', 'ob-badge-logo'
    newStrong.setAttribute 'class', 'ob-badge-title'
    newSpan.setAttribute 'class', 'ob-info'
    newA.setAttribute 'href', '#'

    badgeTitle = document.createTextNode badgeTitle
    badgeInfo = document.createTextNode badgeInfo
    link = document.createTextNode '[more]'

    newA.appendChild link

    newStrong.appendChild badgeTitle
    
    newP.appendChild newStrong
    newP.appendChild badgeInfo
    newP.appendChild newA

    newImgWrapper.appendChild newImg

    newSpan.appendChild newP
    newSpan.appendChild newImgWrapper
    
    newDiv.appendChild newSpan
    
    img.parentNode.insertBefore newDiv, img
    
    newDiv.appendChild img

    obj = document.getElementById badgeID

    newDiv.addEventListener 'click', () =>
      @showLightbox {
        title:assertion.badge.name
        description:assertion.badge.description
        src:img.src
      }

  showLightbox: (data) ->
    @overlay.style.display = 'block'
    @lightbox.style.display = 'block'
    document.getElementById('ob-lightbox').innerHTML = tplfile data
    document.getElementById('close-modal').addEventListener 'click', () =>
      @hideLightbox()

  hideLightbox: () ->
    @overlay.style.display = 'none'
    @lightbox.style.display = 'none'

window.obd = OpenBadgesDisplayer

module.exports.OpenBadgesDisplayer = OpenBadgesDisplayer