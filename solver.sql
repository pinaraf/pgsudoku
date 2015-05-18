WITH
	-- A few 'constants' to start with
	digits as (select d from generate_series(1, 9) d),
	positions as (
		select 
			p,
			array_agg(9 * ((p - 1) / 9) + d) as row_ps,
			array_agg(1 + ((p - 1) % 9) + (d - 1) * 9) as col_ps,
			array_agg(((d-1)/ 3) * 9 + (d - 1) % 3 + ((((p - 1) / 27) * 3 + ((p - 1) % 9) / 3) / 3) * 27 + (((p - 1) / 27) * 3 + ((p - 1) % 9) / 3) % 3 * 3  + 1) as block_ps
		from generate_series(1, 81) p, digits
		group by 1
	),
	dependencies (p, dep) as (
		select
			p,
			unnest(row_ps | col_ps | block_ps) as dep
		from positions order by 1, 2
	),

	
	-- Now import the data
	board AS (select board b, false as recurs_over from sudokus limit 1),
	-- And mix everything up
	possibilities as (
		select
			p,
			array_agg(d) - uniq(sort(array_agg(b[dep]))) as vals
		from dependencies, board, digits
		where
			b[p] = 0 and b[dep] <> 0
		group by p
		having array_length(uniq(sort(array_agg(b[dep]))), 1) = 8
		order by p
	),
	new_board as (
		select
			array_agg(coalesce(possibilities.vals[1], b[positions.p]) order by positions.p) as board,
			false as recurse_over
		from board join positions on true left join possibilities on possibilities.p = positions.p 
	)
select * from new_board;

