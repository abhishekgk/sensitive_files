for i in $(ls); do grep -oE '("|\047)([^"\047]+\/api\/[^"\047]+)("|\047)' $i | sed 's/"//g; s/\047//g' | tee -a paths.txt; done | grep -v cdn | tee -a final_paths.txt
