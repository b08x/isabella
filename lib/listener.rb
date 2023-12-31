require 'yaml'
require 'pocketsphinx-ruby'

class Listener

  ROOT_FOLDER = File.dirname(__FILE__) + '/../'
  CONFIG_FOLDER = ROOT_FOLDER + 'config/'

  FILES = {
    commands:   CONFIG_FOLDER + 'commands.yml',
    dictionary: CONFIG_FOLDER + 'dictionary.dic',
    grammar:    CONFIG_FOLDER + 'grammar.gram'
  }

  def initialize
    @command_keyphrase = 'hey isabella'

    @commands = YAML::load_file(FILES[:commands])

    sphinx_config = Pocketsphinx::Configuration::Grammar.new FILES[:grammar]
    sphinx_config['dict'] = FILES[:dictionary]
    sphinx_config['vad_threshold'] = 3
    #Automatic gain control for c0 ('max', 'emax', 'noise', or 'none')
    sphinx_config['agc'] = "none"
    #Model definition input file
    # sphinx_config['mdef'] = "none"
    #Directory containing acoustic model files
    # sphinx_config['hmm'] = "none"
    sphinx_config['debug'] = 1
    sphinx_config['backtrace'] = "yes"
    sphinx_config['samprate'] = 16000
    @recognizer = Pocketsphinx::LiveSpeechRecognizer.new(sphinx_config)
  end

  def listen
    @recognizer.recognize do |speech|
      puts @speech = speech
      respond
    end
  end

private

  def respond
    delete_tts_file
    @recognizer.pause do
      system 'ruby', *script_and_args
    end
    delete_tts_file
  end

  def delete_tts_file
    system 'rm -f', ROOT_FOLDER + 'tts_playonce'
  end

  def script_and_args
    [ ROOT_FOLDER + "scripts/#{command['script']}.rb", command_arg.to_s ]
  end

  def command
    @commands.find { |c| speech_without_command_keyword =~ %r"#{c['pattern']}" }
  end

  def command_arg
    speech_without_command_keyword.scan(%r"#{command['pattern']}")[0][0]
  end

  def speech_without_command_keyword
    @speech.sub(/#{@command_keyphrase}\s+/, '')
  end

end
