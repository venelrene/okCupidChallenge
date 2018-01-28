require 'json'

INPUT = "input.json"
# OUTPUT = "output.json"
TOP_MATCH = 10

# answer_field = [0,3]
# importance_field = [0,4]

IMPORTANCE_POINT = [0,1, 20, 50, 250]
@questions = Hash.new
@answers = Hash.new
@raw_matches = Hash.new
@output = {:results => Array.new}



# Need to read the File then parse it
def to_json(file)
  file = IO.read file
  JSON.parse file
end

# grab the collection of the common elements in both array
def get_common(profile_a, profile_b)
  @questions[profile_a] & @questions[profile_b]
end

# get answers based off profile & question ID
def get_answers(profileID, questionID)
  i = @questions[profileID].index questionID
  @answers[profileID][i]
end


def satisfaction(head, tail, common)
  score = 0.0
  total = 0.0


  common.each do |c|

    ans_h = get_answers head, c
    ans_t = get_answers tail, c

    accepted = ans_h['acceptableAnswers']
    importance = IMPORTANCE_POINT[ans_t['importance']]

    if accepted.size == 0 || accepted.size == 4
      importance = 0
    end

    if accepted.include? ans_t['answer']
      score += importance
    end
    total += importance
  end

  score / total
end


def get_score(pro_id, key_id)
  common = get_common pro_id, key_id # grab common elements
  sat_1 = satisfaction pro_id, key_id, common
  sat_2 = satisfaction key_id, pro_id, common

  # to get a match % for you and B, we must multiply your satisfactions, and then take the square root:
  # sqrt(% * %) = %
  calc = Math.sqrt (sat_1 * sat_2)
  # currently, we're defining the reasonable margin of error as 1/(size of S)
  err = 1 / (common.length)
  ((calc - err) * 100).round / 100.0
end


# filter result and sort by Top 10 match
def filter_results
  @raw_matches.sort.each do |key, val|
    result = {:profileId => key, :matches => Array.new}

    val.sort_by { |k, v| -v }.first(TOP_MATCH).map.each do |k, v|
      match = {:profileId => k, :score => v}
      result[:matches].push match
    end
    @output[:results].push result
  end
end

# match  possible matches
def find_matches(profiles)
  profiles.each do |d|
    pro_id = d['id'] #profile_id
    #Store & assign empty hash with raw_match hash
    @raw_matches[pro_id] = Hash.new
    # Answers based off profile id stored into answer hash
    @answers[pro_id] = d['answers']

    # loop through each answer and grab the question ID
    q = Array.new
    @answers[pro_id].each do |a|
      q.push a['questionId']
    end

    @questions[pro_id] = q

    @answers.keys.each do |k|
      if pro_id != k
        score = get_score pro_id, k
        @raw_matches[pro_id][k] = score
        @raw_matches[k][pro_id] = score
      end
    end
  end
end





# pull profiles from json
profiles = to_json(INPUT)['profiles']
find_matches(profiles)
filter_results
# make a new file for our output to be written on

File.open("output.json", "w") do |f|
  f.write JSON.pretty_unparse(@output)
end