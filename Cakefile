{exec} = require 'child_process'
sys = require 'sys'

sources = 'src/core src/action'
output = 'dom-modules'

testsSources = 'tests/core tests/html-inserted tests/action'
testsOutput = 'tests/js'

run = (comand) ->
  child = exec comand
  child.stdout.on 'data', (data) -> sys.print data

task 'build', 'build things', ->
  run "coffee -c -j #{output} #{sources}"

task 'watch', 'watch things to be updated', ->
  run "coffee -cw -j #{output} #{sources}"
  run "coffee -cw -o #{testsOutput} #{testsSources}"
