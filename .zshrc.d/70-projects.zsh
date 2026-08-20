# Open a project from ~/Projects
# Usage: projects [name]
function projects() {
    local projects_dir="$HOME/Projects"

    if [[ $# -eq 1 ]]; then
        local project_name="$1"
        builtin cd "$projects_dir/$project_name" || return 1
        echo "Opened project: $project_name"
        return
    fi

    builtin cd "$projects_dir" || return 1
    echo "Projects:"

    local projects=("$projects_dir"/*(N/))
    local i
    for i in {1..${#projects}}; do
        echo "$i. ${projects[$i]:t}"
    done

    local project_index
    print -n "Enter the number of the project you want to open: "
    read project_index

    if [[ $project_index =~ ^[0-9]+$ ]] && (( project_index > 0 && project_index <= ${#projects} )); then
        local project_name="${projects[$project_index]:t}"
        builtin cd "${projects[$project_index]}" || return 1
        echo "Opened project: $project_name"
    else
        echo "Invalid project number."
    fi
}
