class Nanoc::Int::CompilerDSLTest < Nanoc::TestCase
  def test_compile
    # TODO: implement
  end

  def test_route
    # TODO: implement
  end

  def test_layout
    # TODO: implement
  end

  def test_preprocess_twice
    rules_collection = Nanoc::Int::RulesCollection.new(nil)
    compiler_dsl = Nanoc::Int::CompilerDSL.new(rules_collection, {})

    # first time
    io = capturing_stdio do
      compiler_dsl.preprocess {}
    end
    assert_empty io[:stdout]
    assert_empty io[:stderr]

    # second time
    io = capturing_stdio do
      compiler_dsl.preprocess {}
    end
    assert_empty io[:stdout]
    assert_match(/WARNING: A preprocess block is already defined./, io[:stderr])
  end

  def test_per_rules_file_preprocessor
    # Create site
    Nanoc::CLI.run %w( create_site per-rules-file-preprocessor )
    FileUtils.cd('per-rules-file-preprocessor') do
      # Create rep
      item = Nanoc::Int::Item.new('foo', { extension: 'bar' }, '/foo/')

      # Create a bonus rules file
      File.open('more_rules.rb', 'w') { |io| io.write "preprocess { @items['/foo/'][:preprocessed] = true }" }

      # Create other necessary stuff
      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      site.items << item
      dsl = site.compiler.rules_collection.dsl
      io = capturing_stdio do
        dsl.preprocess {}
      end
      assert_empty io[:stdout]
      assert_empty io[:stderr]

      # Include rules
      dsl.include_rules 'more_rules'

      # Check that the two preprocess blocks have been added
      assert_equal 2, site.compiler.rules_collection.preprocessors.size
      refute_nil site.compiler.rules_collection.preprocessors.first
      refute_nil site.compiler.rules_collection.preprocessors.to_a.last

      # Apply preprocess blocks
      site.compiler.preprocess
      assert item.attributes[:preprocessed]
    end
  end

  def test_include_rules
    # Create site
    Nanoc::CLI.run %w( create_site with_bonus_rules )
    FileUtils.cd('with_bonus_rules') do
      # Create rep
      item = Nanoc::Int::Item.new('foo', { extension: 'bar' }, '/foo/')
      rep  = Nanoc::Int::ItemRep.new(item, :default)

      # Create a bonus rules file
      File.open('more_rules.rb', 'w') { |io| io.write "passthrough '/foo/'" }

      # Create other necessary stuff
      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      site.items << item
      dsl = site.compiler.rules_collection.dsl

      # Include rules
      dsl.include_rules 'more_rules'

      # Check that the rule made it into the collection
      refute_nil site.compiler.rules_collection.routing_rule_for(rep)
    end
  end

  def test_passthrough
    with_site do
      # Create rules
      File.open('Rules', 'w') do |io|
        io.write <<EOS
passthrough "/robots/"

compile '*' do ; end
route '*' do ; item.identifier.chop + '-xyz' + item[:extension] ; end
EOS
      end

      # Create items
      assert Dir['content/*'].empty?
      File.open('content/robots.txt', 'w') do |io|
        io.write 'Hello I am robots'
      end

      # Compile
      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      site.compile

      # Check paths
      assert_equal ['output/robots.txt'], Dir['output/*']
    end
  end

  def test_passthrough_no_ext
    with_site do
      # Create rules
      File.open('Rules', 'w') do |io|
        io.write <<EOS
passthrough "/foo/"
EOS
      end

      # Create items
      assert Dir['content/*'].empty?
      File.open('content/foo', 'w') do |io|
        io.write 'Hello I am foo'
      end

      # Compile
      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      site.compile

      # Check paths
      assert_equal ['output/foo'], Dir['output/*']
    end
  end

  def test_passthrough_priority
    with_site do
      # Create rules
      File.open('Rules', 'w') do |io|
        io.write <<EOS
compile '*' do
  filter :erb
end

route '*' do
  item.identifier + 'index.html'
end

passthrough "/foo/"
EOS
      end

      # Create items
      assert Dir['content/*'].empty?
      File.open('content/foo.txt', 'w') do |io|
        io.write "Hello I am <%= 'foo' %>"
      end

      # Compile
      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      site.compile

      # Check paths
      assert_equal ['output/foo'],            Dir['output/*']
      assert_equal ['output/foo/index.html'], Dir['output/foo/*']
    end
  end

  def test_passthrough_with_full_identifiers
    with_site do
      File.open('nanoc.yaml', 'w') do |io|
        io << 'string_pattern_type: legacy' << "\n"
        io << 'data_sources:' << "\n"
        io << '  -' << "\n"
        io << '    type: filesystem' << "\n"
        io << '    identifier_type: full' << "\n"
      end

      # Create rules
      File.open('Rules', 'w') do |io|
        io << 'passthrough \'*\''
      end

      # Create items
      assert Dir['content/*'].empty?
      File.open('content/robots.txt', 'w') do |io|
        io.write 'Hello I am robots'
      end

      # Compile
      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      site.compile

      # Check paths
      assert_equal ['output/robots.txt'], Dir['output/*']
    end
  end

  def test_ignore
    with_site do
      # Create rules
      File.open('Rules', 'w') do |io|
        io.write <<EOS
ignore '/lame/'

passthrough '*'
EOS
      end

      # Create items
      assert Dir['content/*'].empty?
      File.open('content/lame.txt', 'w') do |io|
        io.write 'Hello I am lame'
      end

      File.open('content/notlame.txt', 'w') do |io|
        io.write 'Hello I am not lame'
      end

      # Compile
      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      site.compile

      # Check paths
      assert_equal ['output/notlame.txt'], Dir['output/*']
    end
  end

  def test_ignore_priority
    with_site do
      # Create rules
      File.open('Rules', 'w') do |io|
        io.write <<EOS
compile '*' do
  filter :erb
end

route '*' do
  item.identifier + 'index.html'
end

ignore "/foo/"
EOS
      end

      # Create items
      assert Dir['content/*'].empty?
      File.open('content/foo.txt', 'w') do |io|
        io.write "Hello I am <%= 'foo' %>"
      end

      # Compile
      site = Nanoc::Int::SiteLoader.new.new_from_cwd
      site.compile

      # Check paths
      assert_equal ['output/foo'],            Dir['output/*']
      assert_equal ['output/foo/index.html'], Dir['output/foo/*']
    end
  end

  def test_create_pattern_with_string_with_no_config
    compiler_dsl = Nanoc::Int::CompilerDSL.new(nil, {})

    err = assert_raises(Nanoc::Int::Errors::GenericTrivial) do
      compiler_dsl.create_pattern('/foo/*')
    end
    assert_equal 'Invalid string_pattern_type: ', err.message
  end

  def test_create_pattern_with_string_with_glob_string_pattern_type
    compiler_dsl = Nanoc::Int::CompilerDSL.new(nil, { string_pattern_type: 'glob' })

    pattern = compiler_dsl.create_pattern('/foo/*')
    assert pattern.match?('/foo/aaaa')
    refute pattern.match?('/foo/aaaa/')
    refute pattern.match?('/foo/a/a/a/a')
  end

  def test_create_pattern_with_regex
    compiler_dsl = Nanoc::Int::CompilerDSL.new(nil, { string_pattern_type: 'glob' })

    pattern = compiler_dsl.create_pattern(%r{\A/foo/a*/})
    assert pattern.match?('/foo/aaaa/')
  end

  def test_create_pattern_with_string_with_unknown_string_pattern_type
    compiler_dsl = Nanoc::Int::CompilerDSL.new(nil, { string_pattern_type: 'donkey' })

    err = assert_raises(Nanoc::Int::Errors::GenericTrivial) do
      compiler_dsl.create_pattern('/foo/*')
    end
    assert_equal 'Invalid string_pattern_type: donkey', err.message
  end

  def test_identifier_to_regex_without_wildcards
    # Create compiler DSL
    compiler_dsl = Nanoc::Int::CompilerDSL.new(nil, {})

    actual   = compiler_dsl.instance_eval { identifier_to_regex('foo') }
    expected = %r{^/foo/$}

    assert_equal(expected.to_s,      actual.to_s)
    assert_equal(expected.source,    actual.source)
    assert_equal(expected.kcode,     actual.kcode) if expected.respond_to?(:kcode)
    assert_equal(expected.casefold?, actual.casefold?)
    assert_equal(expected.options,   actual.options)
  end

  def test_identifier_to_regex_with_one_wildcard
    # Create compiler DSL
    compiler_dsl = Nanoc::Int::CompilerDSL.new(nil, {})

    actual   = compiler_dsl.instance_eval { identifier_to_regex('foo/*/bar') }
    expected = %r{^/foo/(.*?)/bar/$}

    assert_equal(expected.to_s,      actual.to_s)
    assert_equal(expected.source,    actual.source)
    assert_equal(expected.kcode,     actual.kcode) if expected.respond_to?(:kcode)
    assert_equal(expected.casefold?, actual.casefold?)
    assert_equal(expected.options,   actual.options)
  end

  def test_identifier_to_regex_with_two_wildcards
    # Create compiler DSL
    compiler_dsl = Nanoc::Int::CompilerDSL.new(nil, {})

    actual   = compiler_dsl.instance_eval { identifier_to_regex('foo/*/bar/*/qux') }
    expected = %r{^/foo/(.*?)/bar/(.*?)/qux/$}

    assert_equal(expected.to_s,      actual.to_s)
    assert_equal(expected.source,    actual.source)
    assert_equal(expected.kcode,     actual.kcode) if expected.respond_to?(:kcode)
    assert_equal(expected.casefold?, actual.casefold?)
    assert_equal(expected.options,   actual.options)
  end

  def test_identifier_to_regex_with_just_one_wildcard
    # Create compiler DSL
    compiler_dsl = Nanoc::Int::CompilerDSL.new(nil, {})

    actual   = compiler_dsl.instance_eval { identifier_to_regex('*') }
    expected = %r{^/(.*?)$}

    assert_equal(expected.to_s,      actual.to_s)
    assert_equal(expected.source,    actual.source)
    assert_equal(expected.kcode,     actual.kcode) if expected.respond_to?(:kcode)
    assert_equal(expected.casefold?, actual.casefold?)
    assert_equal(expected.options,   actual.options)
  end

  def test_identifier_to_regex_with_root
    # Create compiler DSL
    compiler_dsl = Nanoc::Int::CompilerDSL.new(nil, {})

    actual   = compiler_dsl.instance_eval { identifier_to_regex('/') }
    expected = %r{^/$}

    assert_equal(expected.to_s,      actual.to_s)
    assert_equal(expected.source,    actual.source)
    assert_equal(expected.kcode,     actual.kcode) if expected.respond_to?(:kcode)
    assert_equal(expected.casefold?, actual.casefold?)
    assert_equal(expected.options,   actual.options)
  end

  def test_identifier_to_regex_with_only_children
    # Create compiler DSL
    compiler_dsl = Nanoc::Int::CompilerDSL.new(nil, {})

    actual   = compiler_dsl.instance_eval { identifier_to_regex('/foo/*/') }
    expected = %r{^/foo/(.*?)/$}

    assert_equal(expected.to_s,      actual.to_s)
    assert_equal(expected.source,    actual.source)
    assert_equal(expected.kcode,     actual.kcode) if expected.respond_to?(:kcode)
    assert_equal(expected.casefold?, actual.casefold?)
    assert_equal(expected.options,   actual.options)
  end

  def test_identifier_to_regex_with_plus_wildcard
    # Create compiler DSL
    compiler_dsl = Nanoc::Int::CompilerDSL.new(nil, {})

    actual   = compiler_dsl.instance_eval { identifier_to_regex('/foo/+') }
    expected = %r{^/foo/(.+?)/$}

    assert_equal(expected.to_s,      actual.to_s)
    assert_equal(expected.source,    actual.source)
    assert_equal(expected.kcode,     actual.kcode) if expected.respond_to?(:kcode)
    assert_equal(expected.casefold?, actual.casefold?)
    assert_equal(expected.options,   actual.options)
    assert('/foo/bar/' =~ actual)
    refute('/foo/' =~ actual)
  end

  def test_dsl_has_no_access_to_compiler
    compiler_dsl = Nanoc::Int::CompilerDSL.new(nil, {})
    assert_raises(NameError) do
      compiler_dsl.instance_eval { compiler }
    end
  end

  def test_config
    $venetian = 'unsnares'
    compiler_dsl = Nanoc::Int::CompilerDSL.new(nil, { venetian: 'snares' })
    compiler_dsl.instance_eval { $venetian = @config[:venetian] }
    assert_equal 'snares', $venetian
  end
end
