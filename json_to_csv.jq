($accepted_arg | split(",") | map(ltrimstr(" ") | rtrimstr(" ") | ascii_downcase) ) as $accepted_arr
| map(.items)
| add
| map(
    select(
      # Spec: - Status is either open or merged
      ((.state == "open" or .pull_request.merged_at != null) and (.user.type != "Bot"))
      )
    # Spec: Produce a CSV list of PRs with following details: PR URL, PR Title, Repository, Status (Open, Merged), Creation date, Merge date (if applicable), PR Author, Is flag “Hacktoberfest-approved” set?
    | [
        $org,
        # Hacky, but requires far less API calls
        (.repository_url | split("/") | last),
        .html_url,
        .state,
        .created_at,
        .pull_request.merged_at,
        .user.login,
         any(.labels[]; .name | test($hacktoberfest_labeled; "i")),
        ([$accepted_arr[] as $accepted | any(.labels[]; .name | ascii_downcase == $accepted)] | any), # Spec: Is flag “Hacktoberfest-approved” set?
         any(.labels[]; .name | test($spam; "i")), # Spec: Additional labels should be reported in the result (true/false): spam
         any(.labels[]; .name | test($invalid; "i")), # Spec: Additional labels should be reported in the result (true/false): invalid
        (.title | split("\n") | first)

      ]
  )[]
| @csv