
function expect_file 
{
    if [[ ! -f "$1" ]]
    then
        echo "FAILED: File not found $1"
        pwd
        exit 1
    fi
}


function expect_string_in_file
{
    string="$1"
    file="$2" 
    grep -q "$string" "$file"   
}
