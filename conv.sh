#!/bin/bash

# Create output directories
mkdir -p posts
mkdir -p recipes

# Convert blog posts to plain text
for i in ~/git_proj/johngodlee.github.io/_posts/*.md; do
	# Get file name of post, without extension
	name=$(basename "$i" | cut -f 1 -d '.')

	# Convert post from markdown to plain text
	pandoc --from markdown --to plain --reference-links --reference-location=block -o posts/$name.txt $i
    
    # Sanitize plain text
	sed -i 's/\]\[\]/]/g' posts/$name.txt
	sed -i '/%7B%7B%20site\.baseurl%20%7D%7D\/img/d' posts/$name.txt
	sed -i 's|\%7B\%7B\%20site\.baseurl\%20\%7D\%7D|https://johngodlee.github.io|g' posts/$name.txt
	sed -i 's/^\[\[.*\]\]/  {IMAGE}/g' posts/$name.txt

	# Insert title in post
	title=$(awk 'NR==3' $i | sed 's/"//g' | sed 's/title:\s*//g')
	date=$(awk 'NR==4' $i | sed 's/date:\s*//g')
	title_full=$(echo "$title - \[$date\]")
	title_lo=$(echo "$title_full" | sed 's/./=/g')
	sed -i "1i$title_full\n$title_lo\n" "posts/$name.txt"
done

# Create root gophermap and fill with header content 
touch gophermap
cat head > gophermap

# Create array of all posts
all=(posts/*.txt)

# Reverse order of posts array
for (( i=${#all[@]}-1; i>=0; i-- )); do 
	rev_all[${#rev_all[@]}]=${all[i]}
done

# Get 10 most recent posts
recent="${rev_all[@]:0:10}"

# Add recent post links to gophermap
for i in $recent; do
	line=$(head -n 1 $i)
	printf "0$line\t$i\n" >> gophermap
done

# Provide a link to full post archive
echo "
1Archive	posts" >> gophermap

# Create map file for post archive with header content
touch posts/gophermap 
cat archive_head > posts/gophermap 

# Add posts to posts/gophermap
rev_all_base=$(basename ${rev_all[@]})

for i in $rev_all_base; do
	line=$(head -n 1 posts/$i)
	printf "0$line\t$i\n" >> posts/gophermap
done

# Create gophermap for recipes with header content
touch recipes/gophermap 
cat recipes_head > recipes/gophermap 

# Convert recipes to plain text
for i in ~/git_proj/recipes/*/*.md; do
	# Get name of file name recipe, without extension
	name=$(basename "$i" | cut -f 1 -d '.')

	# Convert recipe from markdown to plain text
	pandoc --from markdown --to plain --reference-links --reference-location=block -o recipes/$name.txt $i
done

# Get name of directory recipe resided in for a header in gophermap
dir_list=$(find ~/git_proj/recipes -type d -depth 1 | sed -e '/\.git/d' | sed 's|^\./||')

# Add links for recipes to recipes/gophermap
for i in $dir_list; do
	
	# Insert header into recipes/gophermap
	dir_title=$(basename $i | sed 's/_/ /g' | awk '{ print toupper($0) }')	
	dir_title_lo=$(echo "$dir_title" | sed 's/./=/g')
	printf "\n$dir_title\n\n" >> recipes/gophermap
	
	# Get list of all recipe markdown files
	md_list=$(find $i/* -type f | sed '/README.md/d')

	# Add links for recipes to recipes/gophermap
	for j in $md_list; do
		md_contents_title=$(head -n 1 $j | sed 's/# //g')
		txt_file_loc=$(basename $j | cut -f 1 -d '.' | sed 's/$/.txt/')

		printf "0$md_contents_title\t$txt_file_loc\n" >> recipes/gophermap
	done
done

# Convert CV to plain text
pandoc -f markdown -t plain -o cv.txt ~/git_proj/johngodlee.github.io/cv.md

# Link CV to gophermap
cv="Curriculum Vitae"
cv_lo=$(echo "$cv" | sed 's/./=/g')

sed -i -e "1i$cv\n$cv_lo\n" cv.txt

scp gophermap contact.txt cv.txt johngodlee@tty.sdf.org:/udd/j/johngodlee/gopher
scp posts/* johngodlee@tty.sdf.org:/udd/j/johngodlee/gopher/posts
scp recipes/* johngodlee@tty.sdf.org:/udd/j/johngodlee/gopher/recipes


