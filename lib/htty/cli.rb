require 'readline'
require File.expand_path("#{File.dirname __FILE__}/cli/commands")
require File.expand_path("#{File.dirname __FILE__}/cli/commands/help")
require File.expand_path("#{File.dirname __FILE__}/cli/commands/quit")
require File.expand_path("#{File.dirname __FILE__}/cli/display")
require File.expand_path("#{File.dirname __FILE__}/session")

module HTTY; end

# Encapsulates the command-line interface to _htty_.
class HTTY::CLI

  include HTTY::CLI::Display

  # Returns the HTTY::Session created from command-line arguments.
  attr_reader :session

  # Instantiates a new HTTY::CLI with the specified _command_line_arguments_.
  def initialize(command_line_arguments)
    exit unless @session = rescuing_from(ArgumentError) do
      everything_but_options = command_line_arguments.reject do |a|
        a[0..0] == '-'
      end
      HTTY::Session.new(everything_but_options.first)
    end
  end

  # Takes over stdin, stdout, and stderr to expose #session to command-line
  # interaction.
  def run!
    say_hello
    catch :quit do
      loop do
        begin
          unless (command = prompt_for_command)
            $stderr.puts notice('Unrecognized command')
            puts notice('Try typing ' +
                        strong(HTTY::CLI::Commands::Help.command_line))
            next
          end
          if command == :unclosed_quote
            $stderr.puts notice('Unclosed quoted expression -- try again')
            next
          end
          if ARGV.include?('--debug')
            command.perform
          else
            rescuing_from Exception do
              command.perform
            end
          end
        rescue Interrupt
          puts
          puts notice('Type ' +
                      strong(HTTY::CLI::Commands::Quit.command_line) +
                      ' to quit')
          next
        end
      end
    end
    say_goodbye
  end

private

  def prompt_for_command
    command_line = ''
    while command_line.empty? do
      prompt = prompt(session.requests.last)
      if (command_line = Readline.readline(prompt, true)).nil?
        raise Interrupt
      end
      if whitespace?(command_line) || repeat?(command_line)
        Readline::HISTORY.pop
      end
      command_line.chomp!
      command_line.strip!
    end
    HTTY::CLI::Commands.build_for command_line, :session => session
  end

  def repeat?(command_line)
    command_line == Readline::HISTORY.to_a[-2]
  end

  def whitespace?(command_line)
    command_line.strip.empty?
  end

end

Dir.glob "#{File.dirname __FILE__}/cli/*.rb" do |f|
  require File.expand_path("#{File.dirname __FILE__}/cli/" +
                           File.basename(f, '.rb'))
end
