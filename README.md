# A few years ago I did CodeClan, a 16 week coding bootcamp. 

For my final project I chose to make a Nonogram solver.

This was really stupid. Nonogram puzzles are difficult to solve 
- for computer scientists they're called NP hard which I think means they can't be solved by logic alone.

So my solution (originally in Javascript) used an approach where several methods were called in turn and, 
as long as each set of executions resulted in a number of cells > 0 being solved it continued.

The JS solution could partially solve a small puzzle (10 x 15). The largest can be around 80 * 80.
So I'm having another go this time in Lazarus/Freepascal.
