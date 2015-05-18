WITH
	-- A few 'constants' to start with
	digits as (select d from generate_series(1, 9) d),
	positions as (select p from generate_series(1, 81) p),

	-- Now the recursive part
--	RECURSIVE board(b, recurs_over) as (
--
--	)
	board AS (select board b, false as recurs_over from sudokus limit 1),
	associated_values as (
		select
			p, 
			array_cat(
				array_cat(
					array_agg(b[d1.d + 9 * ((p - 1) / 9)]), -- board_row,
					array_agg(b[1 + (d1.d - 1) * 9 + (p - 1) % 9]) -- board_col,
				),
				array_agg(b[
					-- The block iterator
					((d1.d-1)/ 3) * 9 + (d1.d - 1) % 3 +
					-- Find the block base number from the position
					-- block base number : (((p - 1) / 27) * 3 + ((p - 1) % 9) / 3)
					((((p - 1) / 27) * 3 + ((p - 1) % 9) / 3) / 3) * 27 + (((p - 1) / 27) * 3 + ((p - 1) % 9) / 3) % 3 * 3  +
					1]
				) -- board_block
			) as neighb
		from 
			positions, 
			digits d1, 
			board
		where b[p] = 0
		group by p order by p
	),
	possibilities as (
		select
			p, 
			array_agg(d) as vals
		from
			associated_values,
			digits
		where
			not(d = any(neighb))
		group by p order by p
	),
	new_board as (
		select 
			array_agg(case when array_length(vals, 1) = 1 then vals[1] else b[p.p] end) as board,
			case when array_agg(case when array_length(vals, 1) = 1 then vals[1] else b[p.p] end) = b then true else false end as recurse_over
			
		from
			board, 
			positions p
			left join possibilities on possibilities.p = p.p
		group by b
		order by 1
	)
select * from new_board union all select * from board;