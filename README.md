# H1 Diner Dash Written in Netlogo
IntroCS Fall Term 2017-2018

## H2 Naming file and uploading to github
1. Download file
2. Add whatever
3. Upload the code
4. Press commit (bottom of the page)
5. Update this file (press the pencil icon) 

## H2 Coding format
;What context
to lowerUpper
  command[
    code
    command[
      ;Single semicolon for comments. For long
      ;comments, continue off another single semicolon
      code
    ]
  ]
end

Example:

;Observer context
to go
  every 1 / 60 [
    moveUp
    ask patch 0 0 [
      ;Sets pcolor to a random color
      set pcolor random 138
    ]
  ]
end

to moveUp
  ask turtles[
    fd 1
  ]
end

## H2 What Masataka need to code

## H2 What William need to code
