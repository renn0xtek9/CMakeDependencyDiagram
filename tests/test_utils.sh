
function expect_file 
{
    if [[ ! -f "$1" ]]
    then
        echo "FAILED: File not found $1"
        pwd
        exit 1
    fi
}
