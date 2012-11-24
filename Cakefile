{exec} = require 'child_process'
sys = require 'sys'

sources = 'source/core source/html-inserted source/action'
output = 'dom-modules'

task 'build', 'build things', ->
  child = exec "coffee -c -j #{output} #{sources}"

task 'watch', 'watch things to be updated', ->
  child = exec "coffee -cw -j #{output} #{sources}"
  child.stdout.on 'data', (data) -> sys.print data
