# BFS
# visited - blue, source - green and end - red and obstacle is white

# nodes for 5x5 for now

.equ MAX_SIZE 400
.equ GRID_SIZE 5
.equ target 96

.data

queue: .zero MAX_SIZE    # stores to visit nodes in byte
visited_set: .zero 1000
distance: .zero 1000
.zero 1000    # i am setting queue and stack 1000 bytes apart to avoid overlap
stack: .zero MAX_SIZE    # stack size in bytes

q_err: .string "Something went wrong with the queue :("
debug_st: .string "Found dest, distance: "
queue_size: .word 0    # current queue size
current_node: .word 0

# -1 is start, 1 is obstacle and 2 is end, 0 is bg and 3 is visited
graph: .word  0, 0, 0, 0, 0
row1:  .word  0, 0, 1, 0, 0
row2:  .word  0, 0, 1, 0, 0
row3:  .word -1, 0, 1, 0, 0
row4:  .word  0, 0, 1, 0, 2       # (20 * 4row) + 4col = offset

.text

_start:
    la x2, stack
    
    jal render
    
    li a0, 60    # start pos
    #jal enqueue
    #jal dequeue
    li a1, target    # end pos
    #jal enqueue
    jal bfs
    
    li a7, 4
    la a0, debug_st
    ecall
    li a1 target
    la s0, distance
    add s0, s0, a1
    lw s0, 0(s0)    # distance of source node
    mv a0, s0
    li a7, 36
    ecall
    
    li a7, 10
    ecall

bfs:
    addi x2, x2, -40
    sw t0, 0(x2)
    sw t1, 4(x2)
    sw t2, 8(x2)
    sw s0, 12(x2)
    sw t5, 16(x2)
    sw t6, 20(x2)
    sw x1, 24(x2)
    sw s0, 28(x2)
    sw s1, 32(x2)
    sw s2, 36(x2)
    # takes a0 as start pos
    # takes a1 as end pos
    # for now ill directly load graph using la to save time
    # but take it as an argument to generalize the routine
    
    la s1, visited_set
    li s2, 1
    
    jal enqueue    # storing start node in to_visit queue
    add s5, s1, a0
    sw s2, 0(s5)
    
    
    # now lets loop till queue is empty
    bfs.mainloop:
        la t0, queue_size
        lw t0, 0(t0)
        beq t0, x0, bfs.exitloop
        la t1, graph
        la s1, visited_set
        li s2, 1
        li s4, 20    # used to check if node is on edge of graph
        
        jal x1, dequeue    # a0 will store the node to visit
        
        add t1, t1, a0
        lw t6, 0(t1)
        li s0, 2    # check if end
        
        beq t6, s0, bfs.exitloop
        
        li t2, 3
        
        sw t2, 0(t1)    # marking it as visited
        
        # add left, right, top, bottom as neighbours to queue for visit
        mv t5, a0
        rem s3, t5, s4    # checking if multiple of 20, i.e left most node
        beq s3, x0, skip_left
        addi a0, t5, -4  # left neighbor
        
        jal check_visited
        bne a5, x0, skip_left
        
        jal enqueue
        jal update_distance
        add s5, s1, a0
        sw s2, 0(s5)
        skip_left:
        addi s3, t5, 4    
        rem s3, s3, s4    # check if mmultiple of 16, i.e right most node
        beq s3, x0, skip_right
        addi a0, t5, 4   # right 
        
        jal check_visited
        bne a5, x0, skip_right
        
        jal enqueue
        jal update_distance
        add s5, s1, a0
        sw s2, 0(s5)
        skip_right:
        li s4, 80
        bge t5, s4, skip_bottom
        addi a0, t5, (GRID_SIZE*4) # bottom
        
        jal check_visited
        bne a5, x0, skip_bottom
        
        
        jal enqueue
        jal update_distance
        add s5, s1, a0
        sw s2, 0(s5)
        skip_bottom:
        li s4, 20
        blt t5, s4, skip_top
        addi a0, t5, (-GRID_SIZE*4) # top
        
        jal check_visited
        bne a5, x0, skip_top
        
        jal enqueue
        jal update_distance
        add s5, s1, a0
        sw s2, 0(s5)
        skip_top:
        
        jal render
        beq x0, x0 bfs.mainloop
        
    
    bfs.exitloop:
        lw t0, 0(x2)
        lw t1, 4(x2)
        lw t2, 8(x2)
        lw s0, 12(x2)
        lw t5, 16(x2)
        lw t6, 20(x2)
        lw x1, 24(x2)
        lw s0, 28(x2)
        lw s1, 32(x2)
        lw s2, 36(x2)
        addi x2, x2, 40
        jalr x0, x1, 0


check_visited:
    addi x2, x2, -16
    sw s1, 0(x2)
    sw s2, 4(x2)
    sw t0, 8(x2)
    sw x1, 12(x2)
    
    
    la s1, visited_set
    la s2, graph
    
    li t0, 1
    
    add s2, s2, a0
    lw s2, 0(s2)
    beq s2, t0, obstacle_detected
    
    
    add s1, s1, a0
    
    lw a5, 0(s1)
    
    lw s1, 0(x2)
    lw s2, 4(x2)
    lw t0, 8(x2)
    lw x1, 12(x2)
    addi x2, x2, 16
    jalr x0, x1, 0
    
    obstacle_detected:
        li a5, 1
        lw s1, 0(x2)
        lw s2, 4(x2)
        lw t0, 8(x2)
        lw x1, 12(x2)
        addi x2, x2, 16
        jalr x0, x1, 0

update_distance:
    # a0 is node to be updated
    # t5 is original node
    
    addi x2, x2, -20
    sw s1, 0(x2)
    sw t5, 4(x2)
    sw x1, 8(x2)
    sw s2, 12(x2)
    sw s3, 16(x2)
    
    la s1, distance
    add s3, s1, t5
    lw s3, 0(s3)    # current distance
    addi s3, s3, 1    # incrementing by 1
    add s2, s1, a0
    sw s3, 0(s2)
    
    lw s1, 0(x2)
    lw t5, 4(x2)
    lw x1, 8(x2)
    lw s2, 12(x2)
    lw s3, 16(x2)
    addi x2, x2, 20
    jalr x0, x1, 0
    
    
    

enqueue:
    # takes a0 as value to queue
    addi x2, x2, -16
    sw t0, 0(x2)
    sw t1, 4(x2)
    sw, t2, 8(x2)
    sw x1, 12(x2)
    
    la t0, queue_size
    lw t2, 0(t0)    # value of queue_size
    li t1, MAX_SIZE
    bge t2, t1, queue_error    # performs a check if current size is greater than available size
    
    la t1, queue
    add t1, t1, t2
    sw a0, 0(t1)
    addi t2, t2, 4
    sw t2, 0(t0) # updating queue_size
    
    lw t2, 8(x2)
    lw t1, 4(x2)
    lw t0, 0(x2)
    lw x1, 12(x2)
    addi x2, x2, 16
    
    jalr x0, x1, 0

dequeue:
    # stores dequeued value into a0
    addi x2, x2, -24
    sw t0, 0(x2)
    sw t1, 4(x2)
    sw, t2, 8(x2)
    sw t3, 12(x2)
    sw t4, 16(x2)
    sw x1, 20(x2)
    
    la t0, queue_size
    lw t2, 0(t0)    # value of queue size
    beq t2, x0, queue_error # well if size is 0 we cant dequeue
    
    la t1, queue
    lw a0, 0(t1)    # storing dequeued value into a0 as i said 😎
    li t3, 0
    dequeue.L1:
        beq t3, t2, dequeue.L1.end
        lw t4, 4(t1)
        sw t4, 0(t1)
        
        addi t3, t3, 4
        addi t1, t1, 4
        beq x0, x0, dequeue.L1
    dequeue.L1.end:
    
    addi t2, t2, -4
    sw t2, 0(t0)
    
    lw t0, 0(x2)
    lw t1, 4(x2)
    lw, t2, 8(x2)
    lw t3, 12(x2)
    lw t4, 16(x2)
    lw x1, 20(x2)
    addi x2, x2, 24
    jalr x0, x1, 0
        
    

queue_error:
    li a7, 4
    la a0, q_err
    ecall
    li a7, 10
    ecall    # exiting code cause something went wrong

render:
    addi x2, x2, -28
    sw t0, 0(x2)
    sw t1, 4(x2)
    sw t2, 8(x2)
    sw t3, 12(x2) 
    sw t5, 20(x2)
    sw t6, 24(x2)     # pushing the registers
    sw x1 28(x2)
    
    li t0, 0
    li t1, 0
    li t2, 0
    li t3, 0
    li t5, 0
    li t6, 0
    
    addi t0, t0, GRID_SIZE    # row iteration
    addi t1, t1, GRID_SIZE    # col iteration
    la t2, graph    # make this as a form of argument if u want to generalize more
    la t3, LED_MATRIX_0_BASE
    
    render.L1:
        addi t0, t0, -1
        render.L2:
            addi t1, t1, -1
            lw t5, 0(t2)
            li t6, 0
            beq t5, t6, draw_background
            li t6, -1
            beq t5, t6, draw_start
            li t6, 1
            beq t5, t6, draw_obstacle
            li t6, 2
            beq t5, t6, draw_end
            li t6, 3
            beq t5, t6, draw_visited
            
            draw_visited:
                li t6, 0x000000ff
                sw t6, 0(t3)
                beq x0, x0, L2.end
            draw_background:
                li t6, 0x0
                sw t6, 0(t3)
                beq x0, x0, L2.end
            draw_obstacle:
                li t6, 0x00ffffff
                sw t6, 0(t3)
                beq x0, x0, L2.end
            draw_start:
                li t6, 0x0000ff00
                sw t6, 0(t3)
                beq x0, x0, L2.end
            draw_end:
                li t6, 0x00ff0000
                sw t6, 0(t3)
                beq x0, x0, L2.end
            L2.end:
            
            addi t2, t2, 4
            addi t3, t3, 4
            bne t1, x0, render.L2
        li t1, GRID_SIZE
        bne t0, x0, render.L1
        render.end:
        lw x1 28(x2)
        lw t0, 0(x2)
        lw t1, 4(x2)
        lw t2, 8(x2)
        lw t3, 12(x2) 
        lw t5, 20(x2)
        lw t6, 24(x2) # i know order should be ulta but doesnt matter here
        addi x2, x2, 28
        jalr x0, x1, 0
