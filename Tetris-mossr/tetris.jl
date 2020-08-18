# Defaults
global const DEFAULT_FIELD_WIDTH = 14 # "Pixels" (even)
global const DEFAULT_FIELD_HEIGHT = 20 # "Pixels"
global const DEFAULT_EASY_SPEED = 20 # Game ticks (5ms/tick)
global const DEFAULT_MEDIUM_SPEED = 10 # Game ticks (5ms/tick)
global const DEFAULT_HARD_SPEED = 5 # Game ticks (5ms/tick)
global const DEFAULT_EXTRA_HARD_SPEED = 2 # Game ticks (5ms/tick)
global const ██ = "██" # Block character
global const ─  = "  " # Space character (variable is a box drawing character ASCII 196 ─)
global const ■■ = "[]" # shadow block placement character

# Keyboard inputs
global const KEY_Q = 'q'
global const KEY_E = 'e'
global const KEY_W = 'w'
global const KEY_A = 'a'
global const KEY_S = 's'
global const KEY_D = 'd'
global const KEY_R = 'r'
global const KEY_ESC = '\e'

# ASNI color handling
struct ANSIColors
    red::Function
    bright_red::Function
    green::Function
    yellow::Function
    blue::Function
    magenta::Function
    cyan::Function
    white::Function
    black::Function

    ANSIColors() = new(
        s -> "\e[31m$s\e[0m", # red
        s -> "\e[31;1m$s\e[0m", # bright red
        s -> "\e[32m$s\e[0m", # green
        s -> "\e[33m$s\e[0m", # yellow
        s -> "\e[34m$s\e[0m", # blue
        # s -> "\e[34;1m$s\e[0m", # blue
        s -> "\e[35m$s\e[0m", # magenta
        s -> "\e[36m$s\e[0m", # cyan
        s -> "\e[37m$s\e[0m", # white
        s -> "\e[40m$s\e[0m" # black
    )
end

global const ANSI = ANSIColors()

# Show/hide cursor
hide_cursor() = print("\e[?25l")
show_cursor() = println("\e[?25h")

isopen(s)::Bool = (s == ─) # Check if pixel is open

# Block type
mutable struct Block
    b::Matrix
    Block(b) = new(b)
end
import Base.getindex
getindex(block::Block, i::Int) = block.b[i,:]

# Type aliases
global const Blocks = Array{Block}
global const Field = Array{String}

# Block generation [I L Γ ■ Z Σ T]
global const I = ANSI.cyan(██)
global const bI = Block([─ ─ I ─ ─;
                         ─ ─ I ─ ─;
                         ─ ─ I ─ ─;
                         ─ ─ I ─ ─;
                         ─ ─ ─ ─ ─])

global const L = ANSI.bright_red(██)
global const bL = Block([─ ─ ─ ─ ─;
                         ─ ─ L ─ ─;
                         ─ ─ L ─ ─;
                         ─ ─ L L ─;
                         ─ ─ ─ ─ ─])

global const Γ = ANSI.blue(██)
global const bΓ = Block([─ ─ ─ ─ ─;
                         ─ ─ Γ ─ ─;
                         ─ ─ Γ ─ ─;
                         ─ Γ Γ ─ ─;
                         ─ ─ ─ ─ ─])

global const ■ = ANSI.yellow(██)
global const b■ = Block([─ ─ ─ ─ ─;
                         ─ ─ ─ ─ ─;
                         ─ ■ ■ ─ ─;
                         ─ ■ ■ ─ ─;
                         ─ ─ ─ ─ ─])

global const Z = ANSI.green(██)
global const bZ = Block([─ ─ ─ ─ ─;
                         ─ ─ Z ─ ─;
                         ─ ─ Z Z ─;
                         ─ ─ ─ Z ─;
                         ─ ─ ─ ─ ─])

global const Σ = ANSI.red(██)
global const bΣ = Block([─ ─ ─ ─ ─;
                         ─ ─ ─ Σ ─;
                         ─ ─ Σ Σ ─;
                         ─ ─ Σ ─ ─;
                         ─ ─ ─ ─ ─])

global const T = ANSI.magenta(██)
global const bT = Block([─ ─ ─ ─ ─;
                         ─ ─ T ─ ─;
                         ─ T T T ─;
                         ─ ─ ─ ─ ─;
                         ─ ─ ─ ─ ─])

import Base: rotr90, rotl90, get
rotr90(block::Block) = Block(rotr90(block.b))
rotl90(block::Block) = Block(rotl90(block.b))
get(blocks::Blocks) = rand(blocks)


# Create shadow block by replacing normal block characters with shadow block characters
shadow(block::Block) = Block(map(s->replace(s,██=>■■), block.b))

# Tetris game state to pass around/update
mutable struct GameState
    fw::Int # Field width
    fh::Int # Field height
    speed::Int # Game ticks, difficulty (5ms/tick)
    startX::Int # Starting X position
    startY::Int # Starting Y position
    currX::Int # Current X position
    currY::Int # Current Y position
    score::Int # Game score (numer of lines completed)
    gameover::Bool # Game over indication
    blocks::Blocks # Set of game blocks (constant)
    block::Block # Current active/falling block
    nextblock::Block # Next falling block
    field::Field # Game field with any active blocks

    GameState(;fw = DEFAULT_FIELD_WIDTH,
               fh = DEFAULT_FIELD_HEIGHT,
               speed = DEFAULT_MEDIUM_SPEED,
               startX = (div(fw,2)-1),
               startY = 2,
               currX = startX,
               currY = startY,
               score = 0,
               gameover = false,
               blocks = Blocks([bI,bL,bΓ,b■,bZ,bΣ,bT]),
               block = get(blocks),
               nextblock = get(blocks),
               field = resetfield(fw,fh,score)) =
        new(fw,fh,speed,startX,startY,currX,currY,score,gameover,blocks,block,nextblock,field)
end


function resetfield(fw::Int, fh::Int, score::Int)
    field = Field(fill(─,fh,fw))
    field[:,1] .= "│"
    field[:,end] .= "│"
    field[end,1]  = "└"
    field[end,2:end-1] .= "──"
    field[end,end] = "┘"
    even = iseven(fw)
    field = vcat(["┌" fill("──", Int(floor((fw-2-3)/2)))... repeat("─", even ? 1 : 2) "TE" "TR" "IS" repeat("─", even ? 3 : 2) fill("──", Int(floor((fw-2-3)/2))-1)... "┐"], field)
    field[2,end] *= " ┌───NEXT───┐"
    field[3,end] *= " │          │"
    field[4,end] *= " │          │"
    field[5,end] *= " │          │"
    field[6,end] *= " │          │"
    field[7,end] *= " │          │"
    field[8,end] *= " └──────────┘"
    field[9,end] *= "   Score: $score"
    field
end
resetfield!(state::GameState) = (state.field = resetfield(state.fw, state.fh, state.score))

function clearscreen()
    println("\33[2J")
    hide_cursor()
    # Move cursor to (1,1), then print a bunch of whitespace, then move cursor to (1,1)
    println("\033[1;1H$(join(fill(repeat(" ", 100),100), "\n"))\033[1;1H")
end

# Move cursor to 1,1, print field, move cursor to end
function drawfield(state::GameState, pos::Tuple = (); activefield::Field = state.field)
    if !state.gameover && !isempty(pos)
        # Draw helper shadow block
        activefield = drawshadow(state, pos, activefield)
    end
    # Draw entire field
    println("\033[1;1H$(join(join.([activefield[i,:] for i in 1:size(activefield,1)]),"\n"))\033[$(state.fh+1);$(state.fw+1)H")
end

function drawshadow(state::GameState, pos::Tuple, activefield::Field = state.field)
    shadowblock::Block = shadow(state.block)
    (newpos::Tuple, currY) = ground(shadowblock, state, pos)
    activefield::Field = move(shadowblock, activefield, (newpos[1], newpos[2]-1))
    activefield = move(state.block, activefield, pos)
    return activefield::Field
end

# Update next block
function displaynext!(state::GameState)
    f = state.field[3:6,end]
    for i in 1:4
        f[i] = replace(f[i], r" │.{8,100}│"=>" │"*join(state.nextblock[i])*"│")
    end
    state.field[3:6,end] = f
end

# Update the current and next blocks of the GameState
function updateblock!(state::GameState)
    state.block = state.nextblock
    state.nextblock = get(state.blocks)
end

removelines(state::GameState, linesremoved::Vector) = state.field[setdiff(2:size(state.field,1)-1, linesremoved), 2:end-1]

# Check if a `block` will collide given (x, y) values of the `field`
function collision(block::Block, field::Field, xy::Tuple)
    for (i,x) in enumerate(xy[1]:xy[1]+4)
        for (j,y) in enumerate(xy[2]:xy[2]+4)
            # Collision detection
            if !isopen(block.b[j,i]) && !isopen(field[y,max(1,x)])
                return true
            end
        end
    end
    return false
end


# Move `block` onto the `field` (assuming no collisions)
function move(block::Block, field::Field, xy::Tuple)
    newfield = deepcopy(field)
    for (i,x) in enumerate(xy[1]:xy[1]+4)
        for (j,y) in enumerate(xy[2]:xy[2]+4)
            if !isopen(block.b[j,i])
                newfield[y,x] = block.b[j,i]
            end
        end
    end

    return newfield::Field
end

# Move block to the ground (downwards as far as it can go without collisions)
function ground(block::Block, state::GameState, pos::Tuple)
    local currY = state.currY
    while !collision(block, state.field, pos)
        currY += 1
        pos = (state.currX, currY)
    end
    currY -= 1
    return (pos, currY)
end

# Check if block can rotate, accounting for side wall mitigation
function canrotate(rblock::Block, field::Field, pos::Tuple)
    can::Bool = false
    for i in [0 -1 1 -2 2]
        if !collision(rblock, field, (pos[1]+i, pos[2]))
            if i != 0
                pos = (pos[1]+i, pos[2])
            end
            can = true
            break
        end
    end
    return (can::Bool, pos::Tuple)
end

# Save score
function savescore(lscore::Int) # 1L
    filename=joinpath(@__DIR__, ".highscore")
    if isfile(filename)
        highscore=parse(Int,read(filename,String))
        if lscore > highscore
            writescore(lscore, filename)
        end
    else
        writescore(lscore, filename)
    end
end

function writescore(lscore::Int, filename::String)
    f=open(filename, "w+")
    write(f,string(lscore))
    close(f)
end

# Check if horizontal lines are filled
checkline(field::Field) = [all(map(line->!occursin(─,line), field[i,2:end-1])) for i in 2:size(field,1)-1]


# Key input handling
global BUFFER
function initialize_keyboard_input()
    global BUFFER
    ccall(:jl_tty_set_mode, Int32, (Ptr{Cvoid}, Int32), stdin.handle, true)
    BUFFER = Channel{Char}(100)

    @async while true
        put!(BUFFER, read(stdin, Char))
    end
end

function readinput()
    if isready(BUFFER)
        take!(BUFFER)
    end
end




# Main game loop function
function tetris()
    state::GameState = GameState()

    ticks::Int = 0 # Game clock
    forcedown::Bool = false # Force block down (i.e. un-activate)
    hold::Bool = false # Disables holding certain keys
    restart::Bool = false # Restart by pressing r
    restrict::Bool = false # Restrict left and right movement speed
    initialize_keyboard_input() # Set the input mode to read key presses

    # Field information
    activefield::Field = copy(state.field) # "Active" copy of state.field

    # Blocks (current and next)
    displaynext!(state) # Update next block display

    # Score information
    linesremoved::Vector{Int} = Int[]

    # Clear entire console screen
    clearscreen()

    # Main game loop
    while !state.gameover

        # Game timing
        sleep(0.05) # ms
        ticks += 1
        forcedown = (ticks == state.speed)
        pos::Tuple = (state.currX, state.currY)

        # Reduce flickering by hiding cursor
        hide_cursor()

        # Update score based on lines completed
        if !isempty(linesremoved)
            # Show lines mid-removal
            drawfield(state, pos)

            # Keep score
            state.score += length(linesremoved)

            drawfield(state, pos)

            # Re-draw field with removed lines (and update displayed score)
            reduced_field = removelines(state, linesremoved)
            resetfield!(state)
            state.field[(2+length(linesremoved)):end-1, 2:end-1] = reduced_field

            # Re-draw next block (removed in resetfield! call)
            displaynext!(state)

            # Reset lines removed
            linesremoved = Int[]
            drawfield(state, pos)
        end

        # User input
        key = readinput()
        if key == KEY_A # <LEFT KEY>
            pos = (state.currX-1, state.currY)
        elseif key == KEY_D # <RIGHT KEY>
            pos = (state.currX+1, state.currY)
        elseif key == KEY_S # <DOWN KEY>
            pos = (state.currX, state.currY+1)
        elseif key == KEY_W # <UP KEY>
            # Go down until a collision
            if !hold
                (pos, state.currY) = ground(state.block, state, pos)
                forcedown = true
            end
            hold = true
        elseif (left::Bool = (key == KEY_Q)) || # <LEFT ROTATE>
               (right::Bool = (key == KEY_E))   # <RIGHT ROTATE>
            rotate::Function = left ? rotl90 : rotr90
            rblock::Block = rotate(state.block)
            if !hold
                (rcan::Bool, pos) = canrotate(rblock, state.field, pos)
                if rcan
                    state.block = rblock
                end
            end
            hold = true
        elseif key == KEY_R
            state.gameover = true
            restart = true
        elseif key == KEY_ESC
            state.gameover = true
        else
            # No key
            hold = false
        end

        # Move if no collision
        if !collision(state.block, state.field, pos)
            (state.currX, state.currY) = pos
        else
            pos = (state.currX, state.currY)
        end
        activefield = move(state.block, state.field, pos)

        # Game logic
        if forcedown
            if !collision(state.block, state.field, (pos[1], pos[2]+1))
                # Event: Block can fit down
                state.currY += 1
            else
                # Event: Block can not fit down

                # 1) Lock current piece in field
                state.field[:] = activefield

                # 2) Check if horizontal lines are filled
                filled = checkline(state.field)
                if any(filled)
                    lines = findall(filled) .+ 1
                    state.field[lines, 2:end-1] .= ANSI.white("██") # ■■
                    linesremoved = lines
                else
                    linesremoved = Int[]
                end

                # 3) Choose next piece
                (state.currX, state.currY) = (state.startX, state.startY)
                pos = (state.currX, state.currY)
                updateblock!(state)
                displaynext!(state)

                # 4) If piece does not fit, gameover.
                state.gameover = collision(state.block, state.field,  pos)
            end
            ticks = 0
        end

        # Render output / draw field
        drawfield(state, pos, activefield = activefield)
    end

    if restart
        tetris()
    else
        # Game over!
        savescore(state.score)
        println("╔────────────────────╗")
        println("║      GAMEOVER      ║")
        println("╚────────────────────╝")
        exit()
    end

    return nothing # Suppress REPL
end # function tetris()


tetris()