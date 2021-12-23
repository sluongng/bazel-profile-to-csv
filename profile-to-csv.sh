#!/bin/bash -e

# Profile a quick script to extract bazel analyze-profile outputs into CSV
# so that we can import the output into a spreadsheet service like Google Sheet to
# slice n dice the metrics.
#
# Sample usage:
#
# # Download the artifacts from BuildKite
# > ./bkite-art.sh
#
# # Extract the analyze-profile data to a CSV file
# > ./profile-to-csv.sh | tee output.csv

URL_PREFIX="https://buildkite.com/<my-org>/<my-pipelines>/builds"

# Header row
echo 'date, build id, url, launch phase, init phase, target pattern evaluation phase, interleaved loading-and-analysis phase, preparation phase, execution phase, total run time'

for profile in bazel-profile_*; do
	build_id=$(
		echo "$profile" | awk -F"_" '{print $2}'
	)
	url="$URL_PREFIX/$build_id"

	# store STDERR in separate file for easier processing
	output=$(bazel analyze-profile "$profile" 2>/tmp/bazel-stderr)

	date=$(
		grep 'INFO' /tmp/bazel-stderr |
			sed 's/.*created on \(.*\),.*,/\1/; s/output base.*//'
	)

	launch_time=$(
		echo "$output" |
			awk '/launch phase/ {print $5}'
	)

	init_time=$(
		echo "$output" |
			awk '/init phase/ {print $5}'
	)

	target_eval_time=$(
		echo "$output" |
			awk '/target pattern/ {print $7}'
	)

	analysis_time=$(
		echo "$output" |
			awk '/loading-and-analysis/ {print $6}'
	)

	prep_time=$(
		echo "$output" |
			awk '/preparation/ {print $5}'
	)

	exec_time=$(
		echo "$output" |
			awk '/execution phase/ {print $5}'
	)

	total_time=$(
		echo "$output" |
			awk '/run time/ {print $4}'
	)

	echo "$date, $build_id, $url, $launch_time, $init_time, $target_eval_time, $analysis_time, $prep_time, $exec_time, $total_time"
done

# Clean up
rm -f /tmp/bazel-stderr
