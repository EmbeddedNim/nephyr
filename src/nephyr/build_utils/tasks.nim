
import os, strutils, sequtils
import strformat, tables, sugar

type
  NimbleArgs = object
    projdir: string
    projname: string
    projsrc: string
    projfile: string
    appsrc: string
    args: seq[string]
    child_args: seq[string]
    cachedir: string
    # zephyr_version: string
    app_template: string
    nephyr_path: string
    debug: bool
    forceclean: bool
    distclean: bool
    help: bool

proc parseNimbleArgs(): NimbleArgs =
  var
    projsrc = "main"
    default_cache_dir = "." / projsrc / "nimcache"
    progfile = thisDir() / projsrc / "main.nim"

  if bin.len() >= 1:
    progfile = bin[0]

  var
    idf_idx = -1
    pre_idf_cache_set = false
    override_srcdir = false
    post_idf_args = false
    idf_args: seq[string] = @[]
    child_args: seq[string] = @[]


  for idx in 0..paramCount():
    if post_idf_args:
      child_args.add(paramStr(idx))
      continue
    elif paramStr(idx) == "--":
      post_idf_args = true
      continue

    # setup to find all commands after "zephyr" commands
    if idf_idx > 0:
      idf_args.add(paramStr(idx))
    elif paramStr(idx).startsWith("zephyr"):
      idf_idx = idx
    elif paramStr(idx).startsWith("--nimcache"):
      pre_idf_cache_set = true

  if not projsrc.endsWith("main"):
    if override_srcdir:
      echo "  Warning: Zephyr assumes source files will be located in ./main/ folder "
    else:
      echo "  Error: Zephyr assumes source files will be located in ./main/ folder "
      echo "  got source directory: ", projsrc
      quit(1)

  let
    npathcmd = "nimble --silent path nephyr"
    (nephyrPath, rcode) = system.gorgeEx(npathcmd)
  if rcode != 0:
    raise newException( ValueError, "error running getting Nephyr path using: `%#`" % [npathcmd])

  # TODO: make these configurable and add more examples...
  let
    flags = idf_args.filterIt(it.contains(":")).mapIt(it.split(":")).mapIt( (it[0], it[1])).toTable()
    zephyr_template  = flags.getOrDefault("--zephyr-template", "networking")
    app_template  = flags.getOrDefault("--app-template", "http_server")
    # TODO: handle this for zephyr
    # zephyr_ver  = flags.getOrDefault("--Zephyr-version", "V2.7").replace(".", "_").toUpper()

  result = NimbleArgs(
    args: idf_args,
    child_args: child_args,
    cachedir: if pre_idf_cache_set: nimCacheDir() else: default_cache_dir,
    projdir: thisDir(),
    projsrc: projsrc,
    appsrc: srcDir,
    projname: projectName(),
    projfile: progfile,
    nephyrpath: nephyrPath,
    zephyr_template: zephyr_template,
    app_template: app_template,
    # forceupdatecache = "--forceUpdateCache" in idf_args
    wifi_args: wifidefs,
    debug: "--zephyr-debug" in idf_args,
    forceclean: "--clean" in idf_args,
    distclean: "--dist-clean" in idf_args or "--clean-build" in idf_args,
    help: "--help" in idf_args or "-h" in idf_args
  )

  if result.debug: echo "[Got nimble args: ", $result, "]\n"

task zephyr_list_templates, "List templates available for setup":
  echo "\n[Nephyr] Listing setup templates:\n"
  var nopts = parseNimbleArgs()
  let 
    zephyr_template_dir = nopts.nephyrpath / "nephyr" / "build_utils" / "templates" / "zephyr_templates" 
    app_template_dir = nopts.nephyrpath / "nephyr" / "build_utils" / "templates" / "app_templates" 
    zephyr_template_files = listDirs(zephyr_template_dir)
    app_template_files = listDirs(app_template_dir)

  echo (@["zephyr templates:"] & zephyr_template_files.mapIt(it.relativePath(zephyr_template_dir))).join("\n - ")
  echo (@["app templates:"] & app_template_files.mapIt(it.relativePath(app_template_dir))).join("\n - ")

task zephyr_setup, "Setup a new Zephyr / nephyr project structure":
  echo "\n[Nephyr] setting up project:"
  var nopts = parseNimbleArgs()

  echo "...create project source directory" 
  mkDir(nopts.projsrc)

  echo "...writing cmake lists" 
  let
    cmake_template = readFile(nopts.nephyrpath / "nephyr" / "build_utils" / "templates" / "CMakeLists.txt")
    zephyr_template_files = listFiles(nopts.nephyrpath / "nephyr" / "build_utils" / "templates" / "zephyr_templates" / nopts.zephyr_template )
    app_template_files = listFiles(nopts.nephyrpath / "nephyr" / "build_utils" / "templates" / "app_templates" / nopts.app_template )
  var
    tmplt_args = @[
      "NIMBLE_PROJ_NAME", nopts.projname,
      "NIMBLE_NIMCACHE", nopts.cachedir,
      ]

  writeFile("CMakeLists.txt", cmake_template % tmplt_args)

  tmplt_args.insert(["NIMBLE_NIMCACHE", nopts.cachedir.relativePath(nopts.projsrc) ], 0)

  # writeFile(".gitignore", readFile(".gitignore") & "\n" @["build/", "#main/nimcache/"].join("\n") & "\n")

  echo fmt"{'\n'}Copying zephyr template files for `{nopts.zephyr_template}`:" 
  for tmpltPth in zephyr_template_files:
    let fileName = tmpltPth.extractFilename()
    echo "...copying template: ", fileName, " from: ", tmpltPth, " to: ", getCurrentDir()
    writeFile(nopts.projsrc / fileName, readFile(tmpltPth) % tmplt_args )
  
  echo fmt"{'\n'}Copying app template files for `{nopts.app_template}`:" 
  mkdir(nopts.appsrc / nopts.projname)
  for tmpltPth in app_template_files:
    let fileName = tmpltPth.extractFilename()
    echo "...copying template: ", fileName, " from: ", tmpltPth, " to: ", getCurrentDir()
    writeFile(nopts.appsrc / nopts.projname / fileName, readFile(tmpltPth) % tmplt_args )


task zephyr_install_headers, "Install nim headers":
  echo "\n[Nephyr] Installing nim headers:"
  let
    nopts = parseNimbleArgs()
    cachedir = nopts.cachedir

  if not fileExists(cachedir / "nimbase.h"):
    let nimbasepath = selfExe().splitFile.dir.parentDir / "lib" / "nimbase.h"

    echo("...copying nimbase file into the Nim cache directory ($#)" % [cachedir/"nimbase.h"])
    cpFile(nimbasepath, cachedir / "nimbase.h")
  else:
    echo("...nimbase.h already exists")

task zephyr_clean, "Clean nimcache":
  echo "\n[Nephyr] Cleaning nimcache:"
  let
    nopts = parseNimbleArgs()
    cachedir = nopts.cachedir
  
  if dirExists(cachedir):
    echo "...removing nimcache"
    rmDir(cachedir)
  else:
    echo "...not removing nimcache, directory not found"

  if nopts.forceclean or nopts.distclean:
    echo "...cleaning nim cache"
    rmDir(nopts.cachedir)

  if nopts.distclean:
    echo "...cleaning Zephyr build cache"
    rmDir(nopts.projdir / "build")

  
task zephyr_configure, "Run CMake configuration":
  exec("west build -p always -b ${BOARD} -d build_${BOARD} --cmake-only -c ")


task zephyr_compile, "Compile Nim project for Zephyr program":
  # compile nim project
  var nopts = parseNimbleArgs() 

  echo "\n[Nephyr] Compiling:"

  if not dirExists("main/"):
    echo "\nWarning! The `main/` directory is required but appear appear to exist\n"
    echo "Did you run `nimble zephyr_setup` before trying to compile?\n"

  if nopts.forceclean or nopts.distclean:
    echo "...cleaning nim cache"
    rmDir(nopts.cachedir)

  if nopts.distclean:
    echo "...cleaning Zephyr build cache"
    rmDir(nopts.projdir / "build")

  let
    nimargs = @[
      "c",
      "--path:" & thisDir() / nopts.appsrc,
      "--nomain",
      "--compileOnly",
      "--nimcache:" & nopts.cachedir.quoteShell(),
      "-d:NimAppMain",
      "-d:" & nopts.zephyr_version
    ].join(" ") 
    childargs = nopts.child_args.mapIt(it.quoteShell()).join(" ")
    wifidefs = nopts.wifi_args
    compiler_cmd = nimargs & " " & wifidefs & " " & childargs & " " & nopts.projfile.quoteShell() 
  
  echo "compiler_cmd: ", compiler_cmd
  echo "compiler_childargs: ", nopts.child_args

  if nopts.debug:
    echo "idf compile: command: ", compiler_cmd  

  # selfExec("error")
  cd(nopts.projdir)
  selfExec(compiler_cmd)

task zephyr_build, "Build Zephyr project":
  echo "\n[Nephyr] Building Zephyr/west project:"

  if findExe("west") == "":
    echo "\nError: west not found. Please run the Zephyr export commands: e.g. ` source ~/zephyrproject/zephyr/zephyr-env.sh` and try again.\n"
    quit(2)

  exec("west build -p auto -d build_${BOARD}")


### Actions to ensure correct steps occur before/after certain tasks ###

before zephyr_compile:
  zephyrConfigure()

after zephyr_compile:
  zephyrInstallHeadersTask()

before zephyr_build:
  zephyrConfigure()
  zephyrCompileTask()
  zephyrInstallHeadersTask()
