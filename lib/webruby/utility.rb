require 'fileutils'

module Webruby
  class << self
    def create_file_if_different(filename)
      tmp_filename = "#{filename}.tmp"

      # TODO: add support for case where block is not given,
      # maybe using monkey patching on File#close?
      f = File.open(tmp_filename, 'w')
      yield f
      f.close

      if (!File.exists?(filename)) ||
          (!FileUtils.compare_file(filename, tmp_filename))
        puts "Creating new file: #{filename}!"
        FileUtils.cp(tmp_filename, filename)
      end
      FileUtils.rm(tmp_filename)
    end

    def build_dir
      Webruby::App.config.build_dir
    end

    def full_build_dir
      File.expand_path(build_dir)
    end

    def build_config
      "#{build_dir}/mruby_build_config.rb"
    end

    def full_build_config
      File.expand_path(build_config)
    end

    def entrypoint_file
      Webruby::App.config.entrypoint
    end

    def object_files
      (Dir.glob("#{full_build_dir}/mruby/emscripten/src/**/*.o") +
       Dir.glob("#{full_build_dir}/mruby/emscripten/mrblib/**/*.o") +
       Dir.glob("#{full_build_dir}/mruby/emscripten/mrbgems/**/*.o"))
        .reject { |f|
        f.end_with? "gem_test.o"
      }
    end

    def test_object_files
      (Dir.glob("#{full_build_dir}/mruby/emscripten/test/**/*.o") +
       Dir.glob("#{full_build_dir}/mruby/emscripten/mrbgems/**/gem_test.o"))
    end

    def rb_files
      Dir.glob("#{File.dirname(entrypoint_file)}/**")
    end

    def gem_js_files
      ["#{build_dir}/gem_library.js", "#{build_dir}/gem_append.js"]
    end

    def gem_js_flags
      "--js-library #{build_dir}/gem_library.js --pre-js #{build_dir}/gem_append.js"
    end

    def gem_test_js_files
      ["#{build_dir}/gem_test_library.js", "#{build_dir}/gem_test_append.js"]
    end

    def gem_test_js_flags
      "--js-library #{build_dir}/gem_test_library.js --pre-js #{build_dir}/gem_test_append.js"
    end

    # Prepare exported functions for emscripten

    # Webruby now supports 3 kinds of Ruby source code loading methods:

    # * WEBRUBY.run(): this function loads source code compiled from
    # the app folder, which is already contained in the js file.

    # * WEBRUBY.run_bytecode(): this function loads an array of mruby
    # bytecode, we can generate bytecode using mrbc binary in mruby and
    # load the source code at runtime.

    # * WEBRUBY.run_source(): this function parses and loads Ruby source
    # code on the fly.

    # Note that different functions are needed for the 3 different loading methods,
    # for example, WEBRUBY.run_source requires all the parsing code is present,
    # while the first 2 modes only requires code for loading bytecodes.
    # Given these considerations, we allow 3 loading modes in webruby:

    # 0 - only WEBRUBY.run is supported
    # 1 - WEBRUBY.run and WEBRUBY.run_bytecode are supported
    # 2 - all 3 loading methods are supported

    # It may appear that mode 0 and mode 1 requires the same set of functions
    # since they both load bytecodes, but due to the fact that mode 0 only loads
    # pre-defined bytecode array, chances are optimizers may perform some tricks
    # to eliminate parts of the source code for mode 0. Hence we still distinguish
    # mode 0 from mode 1 here

    COMMON_EXPORTED_FUNCTIONS = ['mrb_open', 'mrb_close'];

    # Gets a list of all exported functions including following types:
    # * Functions exported by mrbgems
    # * Functions required by loading modes
    # * Functions that are customly added by users
    #
    # ==== Attributes
    #
    # * +gem_function_file+ - File name of functions exported by mrbgems, this is
    # generated by scripts/gen_gems_config.rb
    # * +loading_mode+ - Loading mode
    # * +custom_functions+ - Array of custom functions added by user
    def get_exported_functions(gem_function_file, loading_mode, custom_functions)
      loading_mode = loading_mode.to_i

      functions = File.readlines(gem_function_file).map {|f| f.strip}
      functions = functions.concat(custom_functions)
      functions = functions.concat(COMMON_EXPORTED_FUNCTIONS)

      functions << 'webruby_internal_setup'

      # WEBRUBY.run is supported by all loading modes
      functions << 'webruby_internal_run'

      # WEBRUBY.run_bytecode
      functions << 'webruby_internal_run_bytecode' if loading_mode > 0

      # WEBRUBY.run_source
      functions << 'webruby_internal_run_source' if loading_mode > 1

      # WEBRUBY.run_source_file
      functions << 'webruby_internal_run_source_file' if loading_mode > 1

      functions.uniq
    end

    # Generate command line option for exported functions, see
    # gen_exported_functions for argument details
    def get_exported_arg(gem_function_file, loading_mode, custom_functions)
      func_str = get_exported_functions(gem_function_file, loading_mode, custom_functions)
        .map{|f| "'_#{f}'"}.join ', '

      "-s EXPORTED_FUNCTIONS=\"[#{func_str}]\""
    end
  end
end
