require 'open-uri'
require 'json'
require_relative 'constants'

def generate_grid(grid_size)
  # TODO: generate random grid of letters
  grid = []
  # add 65 for ASCII range A-Z
  grid_size.times { grid << (rand(26) + 65).chr }
  return grid
end

def in_the_grid?(attempt, grid)
  # normalize attempt and convert it into an array
  attempt_normal = attempt.upcase.split('').sort
  # normalize the grid and convert it into
  # a hash of arrays of letter instances
  grid_hash =    grid.join.upcase.split('').sort.group_by { |l| l }
  #
  # is it true that all elements of attempt_normal array are present
  # in grid_hash? If so, check that not all instances of that element
  # have already been exhausted (pop)
  attempt_normal.all? { |l| grid_hash[l] ? grid_hash[l].pop : false }
  #
  # another way to do it without the hash:
  # attempt_normal.all? { |l| attempt_normal.count(l) <= grid.count(l) }
end

def systran_en_to_fr(attempt)
  origin = "https://api-platform.systran.net"
  path = "/translation/text/translate"
  query = "?source=en&target=fr&key=#{API_KEY}&input=#{attempt}"
  url = origin + path + query
  systran_response = open(url).read
  systran_response ? JSON.parse(systran_response)["outputs"][0]["output"] : nil
end

def lookup_word(attempt)
  if File.read('/usr/share/dict/words').split("\n").include?(attempt)
    begin
      result = systran_en_to_fr(attempt)
      raise StandardError if result.nil?
      return result
    rescue StandardError => e
      # fallback to system_dict
      puts e.message
      attempt
    end
  end
end

def generate_score(validity, length, time)
  coeffient = 5
  time > 0 ? (validity * length * coeffient / time) : 0
end

def generate_message(score)
  case score
  when 0
    "not in the grid"
  when nil
    "not an english word"
  else
    "well done"
  end
end

def run_game(attempt, grid, start_time, end_time)
  # TODO: runs the game and return detailed hash of result
  time = end_time - start_time
  validity = in_the_grid?(attempt, grid) ? 1 : 0
  translation = lookup_word(attempt) || nil
  score = translation.nil? ? nil : generate_score(validity, attempt.length, time)
  message = generate_message(score)
  { time: time,
    translation: translation,
    score: translation.nil? ? 0 : score,
    message: message }
end
