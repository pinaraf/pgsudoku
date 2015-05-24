WITH
	board_pieces AS (
		SELECT
			1 as board_id,	-- TODO...
			position,
			board[position] as value
		FROM sudokus, generate_series(1, 81) position ORDER BY 1, 2
	),
	digits as (
		SELECT d FROM generate_series(1, 9) d
	),
	dependencies as (
		select
			distinct on (position, dependency)
			p as position,
			case
				when direction = 'row' then
					9 * ((p - 1) / 9) + d
				when direction = 'col' then
					1 + ((p - 1) % 9) + (d - 1) * 9
				else
					((d-1)/ 3) * 9 + (d - 1) % 3 + ((((p - 1) / 27) * 3 + ((p - 1) % 9) / 3) / 3) * 27 + (((p - 1) / 27) * 3 + ((p - 1) % 9) / 3) % 3 * 3  + 1
			end as dependency
		from generate_series(1, 81) p, digits, (values ('row'), ('col'), ('block') ) as d(direction)
		order by 1, 2
	),
	unknowns as (
		SELECT
			bp.position,
			max(digits.d)
		FROM
			board_pieces bp, digits
		WHERE
			bp.value = 0
			AND NOT EXISTS(
				SELECT *
				FROM
					dependencies deps
				JOIN board_pieces bp_dep ON bp_dep.position = deps.dependency
				WHERE deps.position = bp.position AND bp_dep.value = digits.d
			)
		GROUP BY 1 having count(digits.d) = 1 order by 1, 2
	)
select * from unknowns;

