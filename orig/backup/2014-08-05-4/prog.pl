/*
自由課題レポート最終版 (〆切 8月 8日)
提出 8月 4日    by 24115113 林 政行


自由課題: 「スケジュール自動生成」


(1) 実行方法, 実行例

  [ 構成 ]
  ~~~~~~~
    　ファイル構成は以下のようになっている。

    (プログラムの存在するディレクトリ) /
                                   +- prog.pl       (プログラム本体)
                                   +- tasks.dat     (タスク定義ファイル)
                                   +- schedules.dat (スケジュール定義/格納ファイル)

    　このファイル構成の中で、プログラム本体はタスク定義ファイル tasks.dat とスケジュール定義
    ファイル schedules.dat を使用する。従って、これらは前もって作ってある、あるいはプログラム
    から作成可能になっている必要がある。

    　続いて、それぞれの定義ファイルの内容を記述する。


  [ 定義ファイル ]
  ~~~~~~~~~~~~~~
     (a) tasks.dat (タスク定義ファイル)

         tasks.dat の内容の一例
         ------------------------------------------------------------------
          task(t1,task1,10,date(2014,8,15,17,0,0,0,-,-),[]).
          task(t2,task2,22,date(2014,8,15,17,0,0,0,-,-),[t1]).
          task(t3,task3,35,date(2014,8,15,17,0,0,0,-,-),[]).
          task(t4,task4,50,date(2014,8,15,17,0,0,0,-,-),[t2,t3]).
          task(t5,task5,10,-,[]).
         ------------------------------------------------------------------

         ( タスクの記述 )
          ~~~~~~~~~~~~~
          記述フォーマット:
          task(TaskId, Description, ETP, Deadline, [TaskId1, TaskId2, ..., TaskIdN])
                                                   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                                                                 └ dependent tasks

            * ETP = Estimated Time to Process : 推定所要時間 (min)
            * Deadline : この日時までに終わってないといけないという日時。
                     ex. date(2014,07,15,17,00,00,0,-,-)
                     ex. - (時間固定タスク or 締め切りなし)



  　実行方法は、次の用に go. を実行する。するとメインメニューが表示されるので、その後の操作は
  キーボードの矢印キーで行う。具体的に次のようなメニューが表示される。

-------------------------------------------------------
スケジュール自動生成  (2014年8月4日 〜 2014年8月10日)
 -> リロード
    期間設定
    スケジュール初期化
    スケジューリング
    スケジュール表示
    終わり
-------------------------------------------------------

          






*/
%

% ---
% date(Y,M,D,H,Mn,S,Off,TZ,DST)
%    We call this term a date-time structure. The first 5 fields are integers expressing the year,
%    month (1..12), day (1..31), hour (0..23) and minute (0..59). The S field holds the seconds
%    as a floating point number between 0.0 and 60.0. Off is an integer representing the offset
%    relative to UTC in seconds, where positive values are west of Greenwich. If converted from
%    local time (see stamp_date_time/3), TZ holds the name of the local timezone. If the timezone
%    is not known, TZ is the atom -. DST is true if daylight saving time applies to the current
%    time, false if daylight saving time is relevant but not effective, and - if unknown or
%    the timezone has no daylight saving time.
% ---
%



%
% [ スケジュールの記述 ]
%  ~~~~~~~~~~~~~~~~~~
% 記述フォーマット:
%  schedule(StartDateTime, TaskId, IsFixed)
%schedule(date(2014,07,15,17,00,00,0,-,-), t5, true).

%
% * date から TimeStamp への変換:
%     date_time_stamp(date(...), Timestamp).
%
%

% conc
conc([],L,L).
conc([X|L1],L2,[X|L3]) :- conc(L1,L2,L3).

% member
is_member(X,[X|_]).
is_member(X,[Y|Rest]) :-
    X \== Y,
    is_member(X,Rest).

% nth
nth([X|_],0,X) :- !.
nth([_|R],I,X) :- 1 =< I, NextI is I-1, nth(R,NextI,X).

% count
count(Cond, Count) :- (aggregate_all(count, Cond, Count), !; Count is 0).

% choose
choose([],[]).
choose(List,Val) :-
    length(List,Len),
    random(0,Len,Index),
    nth(List,Index,Val).

% load
load :-
    retractAllTasks,
    retractAllSchedules,
    see('tasks.dat'),
    readTasks,
    seen,
    see('schedules.dat'),
    readSchedules,
    seen, !.
retractAllTasks :- (retractall(task(_,_,_,_,_)); true).
retractAllSchedules :- (retractall(schedule(_,_,_)); true).
readTasks :- read(X), (procReadTasks(X), readTasks; !).
readSchedules :- read(X), (procReadSchedules(X), readSchedules; !).
procReadTasks(end_of_file) :- !, fail.
procReadTasks(X) :- X =.. [task | _], !, assert(X).
procReadTasks(_).
procReadSchedules(end_of_file) :- !, fail.
procReadSchedules(X) :- X =.. [schedule | _], !, assert(X).
procReadScheudles(_).

% save
save :-
    tell('tasks.dat'),
    write('% task(tid,taskName,ETP,deadline,dependentTasks)\n\n'),
    writeTasks,
    told, !,
    tell('schedules.dat'),
    write('% schedule(date(Y,M,D,H,I,S,0,-,-),tid,isFixed)\n\n'),
    writeSchedules, !,
    told, !.

writeTasks([]) :- !.
writeTasks([T|Rest]) :- !,
    write(T), write('.'), nl,
    writeTasks(Rest).
writeTasks :-
    (setof(task(X1,X2,X3,X4,X5), task(X1,X2,X3,X4,X5), Set); Set=[]),
    writeTasks(Set).
writeSchedules([]) :- !.
writeSchedules([S|Rest]) :- !,
    write(S), write('.'), nl,
    writeSchedules(Rest).
writeSchedules :-
    write('% static schedules:\n'),
    (setof(schedule(X1,X2,true), schedule(X1,X2,true), Set1), !; Set1=[]),
    writeSchedules(Set1), nl, nl, !,
    write('% dynamic schedules:\n'),
    (setof(schedule(X1,X2,false), schedule(X1,X2,false), Set2), !; Set2=[]),
    writeSchedules(Set2), !.
    

% clear
clear :- (retractall(schedule(_,_,false)),!; true).
clear_all :- (retractall(schedule(_,_,_)), !; true).


% setSchedule
set_schedule(Tid, Timestamp, Fix) :-
    % すでにエントリが存在していたら削除
    (schedule(_, Tid, _), retract(schedule(_,Tid,_)); true), !,
    % エントリを追加
    stamp_date_time(Timestamp, DateTime, 0),
    assert(schedule(DateTime, Tid, Fix)).

% set_cell
set_cell(Row,Col,Tid,Cid) :-
    (retractall(cell(Row,Col,_,_)), !; true),
    assert(cell(Row,Col,Tid,Cid)).
swap_cell(FromRow,FromCol,ToRow,ToCol) :-
    cell(FromRow,FromCol,Tid1,Cid1),
    cell(ToRow,ToCol,Tid2,Cid2), !,
    set_cell(FromRow,FromCol,Tid2,Cid2),
    set_cell(ToRow,ToCol,Tid1,Cid1).

% for_all
for_all([], _) :- !.
for_all([X|R], V) :- not(not(X = V)), for_all(R).

% find
find_max([L|Ls], Max) :- find_max(Ls, L, Max).
find_max([], Max, Max).
find_max([L|Ls], Max0, Max) :-
    Max1 is max(L, Max0),
    find_max(Ls, Max1, Max).

find_min([L|Ls], Min) :- find_min(Ls, L, Min).
find_min([], Min, Min).
find_min([L|Ls], Min0, Min) :-
    Min1 is min(L, Min0),
    find_min(Ls, Min1, Min).

find_day(FromYear,FromMonth,FromDay,ToYear,ToMonth,ToDay,Year,Month,Day,DayOfTheWeek) :-
    between(FromYear,ToYear,Year),
    (FromYear =:= Year, Year =:= ToYear, find_day(FromMonth,FromDay,ToMonth,ToDay,Year,Month,Day,DayOfTheWeek);
     FromYear =:= Year, Year  <  ToYear, find_day(FromMonth,FromDay,     13,ToDay,Year,Month,Day,DayOfTheWeek);
     FromYear  <  Year, Year  <  ToYear, find_day(        0,FromDay,     13,ToDay,Year,Month,Day,DayOfTheWeek);
     FromYear  <  Year, Year =:= ToYear, find_day(        0,FromDay,ToMonth,ToDay,Year,Month,Day,DayOfTheWeek)).
find_day(FromMonth,FromDay,ToMonth,ToDay,Year,Month,Day,DayOfTheWeek) :-
    between(FromMonth,ToMonth,Month), between(1,12,Month),
    (FromMonth =:= Month, Month =:= ToMonth, find_day(FromDay,ToDay,Year,Month,Day,DayOfTheWeek);
     FromMonth =:= Month, Month  <  ToMonth, find_day(FromDay,   32,Year,Month,Day,DayOfTheWeek);
     FromMonth  <  Month, Month  <  ToMonth, find_day(      0,   32,Year,Month,Day,DayOfTheWeek);
     FromMonth  <  Month, Month =:= ToMonth, find_day(      0,ToDay,Year,Month,Day,DayOfTheWeek)).
find_day(FromDay,ToDay,Year,Month,Day,DayOfTheWeek) :-
    between(FromDay,ToDay,Day), between(1,31,Day),
    day_exists(Year,Month,Day,DayOfTheWeek).

set_config(Key,Value) :-
    (retractall(my_config(Key,_)), !; true),
    assert(my_config(Key,Value)).

get_config(Key,Value) :-
    current_predicate(my_config/2),
    my_config(Key,Value).

get_schedule_span(ScheduleFrom, ScheduleTo) :-
    (get_config('ScheduleFrom',ScheduleFrom), !;
     get_time(Now), stamp_to_date(Now,Y,M,D), date_time_stamp(date(Y,M,D,0,0,0,0,-,-),ScheduleFrom),
     set_config('ScheduleFrom',ScheduleFrom)),
    (get_config('ScheduleTo',ScheduleTo), !; ScheduleTo is ScheduleFrom + 604799, set_config('ScheduleTo',ScheduleTo)).
get_schedule_span(FromYear,FromMonth,FromDay,ToYear,ToMonth,ToDay) :-
    get_schedule_span(From, To),
    stamp_to_date(From,FromYear,FromMonth,FromDay),
    stamp_to_date(To,ToYear,ToMonth,ToDay).

get_day_span(DayFrom, DayTo) :-
    (get_config('DayFrom',DayFrom), !; DayFrom is 800),
    (get_config('DayTo',DayTo), !; DayTo is 1200). % FIXME

get_cell_size('row',RowSize) :-
    get_day_span(DayFrom,DayTo),
    count_rows(DayFrom,DayTo,RowSize0),
    RowSize is RowSize0 + 1.

get_cell_size('col',ColSize) :-
    count(day(_,_,_,_), ColSize).

day_exists(Year,Month,Day,DayOfTheWeek) :-
    (is_member(Month, [1,3,5,7,9,11]), between(1,31,Day);
     is_member(Month, [4,6,8,10,12]), between(1,30,Day);
     Month = 2, ((Year mod 4 =:= 0, Year mod 100 =\= 0;  is_member(Year mod 900, [200, 600]), between(1,30,Day));
		 between(1,29,Day))),
    day_of_the_week(date(Year,Month,Day),DayOfTheWeek), !.

stamp_to_date(Timestamp, Y, M, D) :-
    stamp_date_time(Timestamp, Date, 'UTC'),
    Date = date(Y,M,D,_,_,_,_,_,_).

stamp_to_time(Timestamp, H, M, S) :-
    stamp_date_time(Timestamp, Date, 'UTC'),
    Date = date(_,_,_,H,M,S,_,_,_).

count_rows(FromTime, ToTime, RowSize) :-
    Diff is ToTime-FromTime,
    H is floor(Diff / 100) + floor((Diff mod 100)/60),
    I is ((Diff mod 100) mod 60),
    RowSize is floor(H*6) + floor(I/10).

step(Low,High,Step,Int) :- between(Low,High,Int), (Int-Low) mod Step =:= 0.

count_days(Y1,M1,D1,Y2,M2,D2,Count) :-
    (retractall(tmp_day(_,_,_,_)), !; true),
    forall(find_day(Y1,M1,D1,Y2,M2,D2,Year,Month,Day,DayOfTheWeek),
	   assert(tmp_day(Year,Month,Day,DayOfTheWeek))),
    count(tmp_day(_,_,_,_),Count),
    (retractall(tmp_day(_,_,_,_)), !; true).

stamp_to_cell(Timestamp,Row,Col) :-
    get_schedule_span(ScheduleFrom,ScheduleTo),
    ScheduleFrom =< Timestamp, Timestamp =< ScheduleTo,
    stamp_to_date(ScheduleFrom,Y0,M0,D0),
    stamp_to_date(Timestamp,Y1,M1,D1),
    count_days(Y0,M0,D0,Y1,M1,D1,Col),
    get_day_span(DayFrom,DayTo),
    stamp_to_time(Timestamp,H1,I1,_),
    Time is H1*100+I1,
    DayFrom =< Time, Time =< DayTo,
    count_rows(DayFrom,Time,Row0),
    Row is Row0 + 1.

cell_to_stamp(Row,Col,Timestamp) :-
    get_schedule_span(ScheduleFrom,ScheduleTo),
    get_day_span(DayFrom,_),
    get_cell_size('row',RowSize),
    stamp_to_date(ScheduleFrom,Y0,M0,D0),
    stamp_to_time(ScheduleFrom,H0,I0,S0),
    D1 is D0 + (Col-1) + floor(Row/RowSize),
    H1 is H0 + floor((DayFrom/100))+floor((Row mod RowSize)/6),
    I1 is I0 + ceil(DayFrom mod 100) + ceil(((Row-1) mod RowSize) mod 6),
    date_time_stamp(date(Y0,M0,D1,H1,I1,S0,0,-,-), Timestamp),
    Timestamp =< ScheduleTo.

cell_distance(Row1,Col1,Row2,Col2,D) :-
    get_cell_size('row',RowSize),
    get_cell_size('col',ColSize),
    between(1,RowSize,Row1), between(1,RowSize,Row2),
    between(1,ColSize,Col1), between(1,ColSize,Col2),
    D is (Col2-Col1)*RowSize + (Row2-Row1).


% eval
eval(Tid, Cid, Ev) :-
    chunk(Tid, Cid, _),
    findall(constraint(Tid,Cid,Type,Val), constraint(Tid,Cid,Type,Val), Constraints),
    eval(Constraints, Ev).
eval([],0) :- !.
eval([C|Rest], Weight) :-
    eval(Rest, Weight1),
    C = constraint(Tid,Cid,Type,Val),
    (penalty(Type,Tid,Cid,Val,Weight2), !, Weight is Weight1 + Weight2;
     Weight is Weight1 + 10000).

penalty('deadline', Tid, Cid, Cell, Weight) :-
    Cell = cell(Drow,Dcol,_,_),
    cell(Mrow,Mcol,Tid,Cid),
    cell_distance(Mrow,Mcol,Drow,Dcol,D),
    (0  < D, Weight is 0, !;
     D =< 0, Weight is abs(D)+1+5000).

penalty('dependent', Tid, Cid, Dchunk, Weight) :-
    Dchunk = chunk(Dtid,Dcid,_),
    cell(Mrow,Mcol,Tid,Cid),
    cell(Drow,Dcol,Dtid,Dcid),
    cell_distance(Drow,Dcol,Mrow,Mcol,D),
    (D = 10, Weight is 0, !;
     1 < D,  Weight is abs(D-10), !;
     D < 1,  Weight is abs(D)+1000).

penalty('sequential', Tid, Cid, Chunk, Weight) :-
    Chunk = chunk(Tid,Pcid,_),
    cell(Crow,Ccol,Tid,Cid),
    cell(Prow,Pcol,Tid,Pcid),
    cell_distance(Prow,Pcol,Crow,Ccol,D),
    (D = 1, Weight is 0, !;
     1 < D, Weight is  (D-1)+100, !;
     D < 1, Weight is (-D+1)+100).

penalty('fixed', Tid, Cid, Cell, Weight) :-
    Cell = cell(Row,Col,_,_),
    cell(Crow,Ccol,Tid,Cid),
    cell_distance(Row,Col,Crow,Ccol,D),
    (0 = D, Weight is 0, !;
     Weight is abs(D)+10000).

penalty('soft_fixed', Tid, Cid, Cell, Weight) :-
    Cell = cell(Row,Col,_,_),
    cell(Crow,Ccol,Tid,Cid),
    cell_distance(Row,Col,Crow,Ccol,D),
    (D = 0, Weight is 0, !;
     Weight is abs(D)+500).
     


% prepare
prepare :-
    prepare_days,
    prepare_cells,
    prepare_chunks,
    prepare_constraints.

prepare_days :-
    (retractall(day(_,_,_,_)); true), !,
    get_schedule_span(FromYear,FromMonth,FromDay,ToYear,ToMonth,ToDay),
    forall(find_day(FromYear,FromMonth,FromDay,ToYear,ToMonth,ToDay,Year,Month,Day,DayOfTheWeek),
	   assert(day(Year,Month,Day,DayOfTheWeek))).

prepare_cells :-
    (retractall(cell(_,_,_,_)), !; true),
    get_cell_size('row',RowSize),
    get_cell_size('col',ColSize),
    forall(between(1,RowSize,Row),
	   forall(between(1,ColSize,Col),
		  (assert(cell(Row,Col,-,-)), !; true))).

prepare_chunks :-
    (retractall(chunk(_,_,_)), !; true),
    get_schedule_span(ScheduleFrom,_),
    get_day_span(DayFrom,_),
    StartTime is ScheduleFrom + floor(DayFrom/100)*3600 + min(ceil(DayFrom mod 100),60)*60,
    forall(task(Tid,_,ETP,Deadline,_),(
	       (
		   % Deadline を超えたタスクは無視する
		   (Deadline = '-', !; date_time_stamp(Deadline,DeadTime), DeadTime =< StartTime), !, true;
		   % Deadline に間に合うタスクはチャンクに分割してアサート
		   ChunkSize is ceil(ETP / 10),
		   (ETP mod 10 =:= 0, LastLen is 10, !; LastLen is ETP mod 10),
		   assert(chunk_size(Tid,ChunkSize)),
		   (ChunkSize =:= 1, !, assert(chunk(Tid,1,LastLen));
		    1 < ChunkSize, assert(chunk(Tid,1,10)),
		    To is ChunkSize-1, forall(between(2,To,I), (assert(chunk(Tid,I,10)))),
		    assert(chunk(Tid,ChunkSize,LastLen)))
	       )
	  )).



% 制約の準備
prepare_constraints :-
    % 既存の制約をすべて削除
    (retractall(constraint(_,_,_,_)), !; true),
    % Deadline の制約
    forall(chunk(Tid,1,_),(
	       % 締切の取得
	       task(Tid,_,_,Deadline,_),
	       % タスク分割数の取得
	       %chunk_size(Tid,Cid),
	       (
		   % Deadline が無ければ Deadline 制約は加えない
		   Deadline = '-', !, true
		   ;
		   % Deadline があれば Deadline 制約を加える
		   date_time_stamp(Deadline,Timestamp),
		   (
		       stamp_to_cell(Timestamp,Row,Col),
		       forall(chunk(Tid,Cid,_), assert(constraint(Tid,Cid,'deadline',cell(Row,Col,-,-))))
		       ;
		       true
		   )
	       )
	  )),
    forall(chunk(Tid,1,_),(
	       % 依存タスクの取得
	       task(Tid,_,_,_,Deps),
	       % 依存タスクの制約を処理する
	       prepare_constraints('dependent',Tid,Deps)
	  )),
    % 分割されたタスクが連続する、という制約
    forall(chunk(Tid,Cid,_),(
	       (PrevCid is Cid-1, chunk(Tid,PrevCid,Len), !, assert(constraint(Tid,Cid,'sequential',chunk(Tid,PrevCid,Len))); true)
	  )),
    % 固定スケジュールの制約
    forall(schedule(DateTime,Tid,true),(
	       date_time_stamp(DateTime,Timestamp),
	       (stamp_to_cell(Timestamp,Row,Col), !, assert(constraint(Tid,1,'fixed',cell(Row,Col,-,-)));
		true)
	  )),
    % 今までのスケジュールをなるべく動かさない制約
    forall(schedule(DateTime,Tid,false),(
	       date_time_stamp(DateTime,Timestamp),
	       (stamp_to_cell(Timestamp,Row,Col), !, assert(constraint(Tid,1,'soft_fixed',cell(Row,Col,-,-)));
		true)
	  )).
prepare_constraints('dependent',_,[]) :- !.
prepare_constraints('dependent',Tid,[Dep|Rest]) :- !,
    (
	% 依存タスクの最後の分割の Cid (Chunk Id)
	chunk_size(Dep,Cid), !,
	% 依存タスクの最後の分割が存在することを確認
	chunk(Dep,Cid,Len),
	% 依存元タスク (自タスク) の最初の分割が依存タスクの最後の分割よりも後に来る制約を加える
	assert(constraint(Tid,1,'dependent',chunk(Dep,Cid,Len)))
	; true
    ),
    % 次の依存制約を処理
    prepare_constraints('dependent',Tid,Rest).


% セルからスケジュールへ
apply_schedule :-
    (retractall(schedule(_,_,false)), !; true),
    forall(cell(Row,Col,Tid,1), (
	       (schedule(_,Tid,true), !, true;
		cell_to_stamp(Row,Col,Timestamp),
		stamp_to_date(Timestamp,Y,M,D),
		stamp_to_time(Timestamp,H,I,S),
		assert(schedule(date(Y,M,D,H,I,S,0,-,-),Tid,false)))
	  )).



% CSP 関連
init_csp :-
    count(chunk(_,_,_),ChunkNum),
    count(cell(_,_,_,_),CellNum),
    findall(chunk(Tid,Cid,Len),chunk(Tid,Cid,Len),Chunks),
    get_cell_size('row',RowSize),
    randset(ChunkNum, CellNum, PosList),
    init_csp(Chunks, PosList, RowSize).
init_csp([],_,_) :- !.
init_csp([Chunk|Rest1], [Pos|Rest2], RowSize) :-
    init_csp(Rest1,Rest2,RowSize),
    Row is (Pos mod RowSize) + 1,
    Col is ceil(Pos  /  RowSize),
    Chunk = chunk(Tid,Cid,_),
    set_cell(Row,Col,Tid,Cid).

select_move_cell(Evsr,LastRow,LastCol,Row,Col,Ev) :-
    (cell(LastRow,LastCol,Ltid,Lcid), !; Ltid = '-', Lcid = '-'), !,
    select_move_cell_(Evsr,Ltid,Lcid,Row,Col,Ev), !, writef('choose %t,%t(%t)',[Row,Col,Ev]),nl.
select_move_cell_([],_,_,-1,-1,0).
select_move_cell_([X|Rest],Ltid,Lcid,Row,Col,Ev) :-
    (X = ev(_,Ltid,Lcid), !, select_move_cell_(Rest,Ltid,Lcid,Row,Col,Ev);
     X = ev(Ev,Tid,Cid), cell(Row,Col,Tid,Cid)).

decide_move_to(FromRow,FromCol,FromEv,ToRow,ToCol,ToEv) :-
    (retractall(ev_at(_,_,_)), !; true),
    forall(candidate_move_to(FromRow,FromCol,ToRow,ToCol),(
	       eval_when_swapped(FromRow,FromCol,ToRow,ToCol,Ev),
	       assert(ev_at(ToRow,ToCol,Ev))
	  )),
    bagof(Ev, (Row,Col)^ev_at(Row,Col,Ev), Evs),
    listing(ev_at),
    find_min(Evs,ToEv),
    bagof(ev_at(Row,Col,ToEv), (Row,Col)^ev_at(Row,Col,ToEv), MinEvs),
    choose(MinEvs,MinVal),
    MinVal = ev_at(ToRow,ToCol,_).
    %(retractall(ev_at(_,_,_)), !; true).

%candidate_move_to(FromRow,FromCol,ToRow,ToCol) :-
%    get_cell_size('row',RowSize),
%    get_cell_size('col',ColSize),
%    RowMin is FromRow - 10, RowMax is FromRow + 10,
%    ColMin is FromCol - 10, ColMax is FromCol + 10,
%    between(1,RowSize,ToRow), between(RowMin,RowMax,ToRow),
%    between(1,ColSize,ToCol), between(ColMin,ColMax,ToCol).
%    %(FromRow = ToRow, FromCol = ToCol, !, false; true).
candidate_move_to(FromRow,FromCol,ToRow,ToCol) :-
    MaxDist is 10, MinDist is -10,
    between(MinDist,MaxDist,D),
    cell_distance(FromRow,FromCol,ToRow,ToCol,D).

eval_when_swapped(FromRow,FromCol,ToRow,ToCol,Ev) :-
    cell(FromRow,FromCol,Tid1,Cid1),
    cell(ToRow,ToCol,Tid2,Cid2),
    (Tid1 \== '-', eval(Tid1,Cid1,Ev1), !; Ev1 = 0),
    (Tid2 \== '-', eval(Tid2,Cid2,Ev2), !; Ev2 = 0),
    swap_cell(FromRow,FromCol,ToRow,ToCol),
    (Tid1 \== '-', eval(Tid1,Cid1,Ev1s), !; Ev1s = 0),
    (Tid2 \== '-', eval(Tid2,Cid2,Ev2s), !; Ev2s = 0),
    Ev is Ev1s+Ev2s, %TODO
    swap_cell(FromRow,FromCol,ToRow,ToCol).

calc_total_ev([],0).
calc_total_ev([0],0).
calc_total_ev([X|Rest],TotalEv) :- calc_total_ev(Rest,TotalEv0), X = ev(Ev,_,_), TotalEv is TotalEv0 + Ev.
total_ev(TotalEv, Evsr) :-
    (retractall(ev_of(_,_,_)), !; true),
    forall(eval(Tid,Cid,Ev), assert(ev_of(Tid,Cid,Ev))),
    setof(ev(Ev,Tid,Cid), (Tid,Cid)^ev_of(Tid,Cid,Ev), Evs),
    reverse(Evs,Evsr),
    calc_total_ev(Evsr,TotalEv).

solve_loop(RemItr,LastRow,LastCol,LastTotalEv,FinalTotalEv) :-
    0 < RemItr,
    % 評価値の計算
    calc_total_ev(TotalEv, Evsr),
    %
    cls, location(1,1),
    writef('Remaining Iteration: %t, TotalEv = %t',[RemItr,TotalEv]), nl,
    print_cells, nl,
    % 動かすセルの決定
    select_move_cell(Evsr,LastRow,LastCol,FromRow,FromCol,FromEv), !,
    (
	% ループの終了条件
	FromEv = 0, FinalTotalEv = TotalEv, !, true;
	0 < LastTotalEv, LastTotalEv < TotalEv, FinalTotalEv = LastTotalEv, !, true;
	% 移動先の検討
	decide_move_to(FromRow,FromCol,FromEv,ToRow,ToCol,ToEv),
	%cls,print_cells, nl,
	%cell(FromRow,FromCol,Tid,Cid), listing(ev_of),
	writef('[%5r] moving (%t-%t) (%t,%t) -> (%t,%t), Ev: %t --> %t',[RemItr,Tid,Cid,FromRow,FromCol,ToRow,ToCol,FromEv,ToEv]),nl,
	%listing(constraint(Tid,Cid,X,Y)),nl,
	get_single_char(_),
	(
	    ToEv =< FromEv,
	    % 移動
	    swap_cell(FromRow,FromCol,ToRow,ToCol),
	    NextRemItr is RemItr - 1,
	    solve_loop(NextRemItr,ToRow,ToCol,TotalEv,FinalTotalEv), !;
	    % 移動しない
	    FromEv < ToEv,
	    NextRemItr is RemItr - 1,
	    solve_loop(NextRemItr,FromRow,FromCol,TotalEv,FinalTotalEv)
	)
    ).

solve_csp :-
    prepare,
    init_csp,
    writef('既存のスケジュール:'),nl,writef('---------------------------------------'),nl,listing(schedule),nl,
    writef('存在する制約:'),nl,writef('---------------------------------------'),nl,listing(constraint),nl,
    get_single_char(_),
    solve_loop(10000,-1,-1,-1,_),
    cls,
    location(1,1),
    write('スケジューリング結果:'),
    print_cells,
    get_single_char(_).



% print
print_cells :-
    get_cell_size('row',RowSize),
    get_cell_size('col',ColSize),
    forall(between(1,ColSize,Col), print_head(Col)),
    forall(between(1,RowSize,Row), print_left(Row)),
    forall(between(1,RowSize,Row),(
	       forall(between(1,ColSize,Col),(
			  print_cell(Row,Col), !; true
		     ))
	  )).
print_head(Col) :-
    X is 3 + Col*5, Y is 3,
    location(X,Y),
    writef('%4c',[Col]).
print_left(Row) :-
    X is 1, Y is 3 + Row,
    location(X,Y),
    writef('%3r',[Row]).
print_cell(Row,Col) :-
    cell(Row,Col,-,_), !,
    X is 3 + Col*5 , Y is 3 + integer(Row),
    location(X,Y),
    (constraint(Tid,_,'deadline',cell(Row,Col,_,_)), !, writef('<%t>', [Tid]);
     ev_at(Row,Col,Ev), !, writef('%4c',[Ev]);
     writef('%4c',['-'])).
print_cell(Row,Col) :-
    cell(Row,Col,Tid,Cid), !,
    X is 3 + Col*5 , Y is 3 + integer(Row),
    location(X,Y),
    writef('%2r-%2l',[Tid,Cid]).










% terminal control
cls :- write('\e[2J').
cls_right :- write('\e[0K').
cls_left :- write('\e[1K').
cls_line :- write('\e[2K').
location(X,Y) :- write('\e['),write(Y),write(';'),write(X),write('H').
right(X) :- write('\e['),write(X),write('C').
left(X) :- write('\e['),write(X),write('D').
up(X) :- write('\e['),write(X),write('A').
down(X) :- write('\e['),write(X),write('B').

% symbol
symbol(I,R) :-
    NextR is R+1,
    symbol(NextR),
    location(2,I), write('->'),
    location(1,I).
symbol(2) :- !,
    location(2,2), write('  ').
symbol(R) :- !,
    2 < R,
    location(2,R), write('  '),
    NextR is R-1,
    symbol(NextR).

% input
input(P,S,R) :-
    get_single_char(Input), !,
    proc_input(P,S,R,Input,N),
    (Input = 13, true; input(P,N,R)).

proc_input(P,S,_,13,S) :- !, proc(P,S).
proc_input(_,S,R,65,N) :- (3 =< S, N is S-1, symbol(N,R), !; N = S).
proc_input(_,S,R,66,N) :- (S =< R, N is S+1, symbol(N,R), !; N = S).
proc_input(_,S,_, _,S) :- !.

% main
my_main :- my_main(2).
my_main(I) :-
    main_menu,
    symbol(I,6),
    input('main',I,6), !.

main_menu :- !,
    get_schedule_span(FromYear,FromMonth,FromDay,ToYear,ToMonth,ToDay),
    writef('スケジュール自動生成  (%t年%t月%t日 〜 %t年%t月%t日)', [FromYear,FromMonth,FromDay,ToYear,ToMonth,ToDay]),nl,
    writef('    リロード'), nl,
    writef('    期間設定'), nl,
    writef('    スケジュール初期化'), nl,
    writef('    スケジューリング'), nl,
    writef('    スケジュール表示'), nl,
    writef('    終わり').

proc('main', 2) :- !, cls, location(1,1), reload.
proc('main', 3) :- !, cls, location(1,1), setting.
proc('main', 4) :- !, cls, location(1,1), reset_schedule.
proc('main', 5) :- !, cls, location(1,1), do_schedule.
proc('main', 6) :- !, cls, location(1,1), print_schedule.
proc('main', 7) :- !, cls, location(1,1), end.


% リロード
reload :-
    load,
    my_main(2).

% 期間設定
setting :-
    write('期間設定'), nl,
    write('  スケジューリング開始日を入力 [\'YYYY-MM-DD\'.]'), nl,
    read(StartTerm1),
    string_concat(StartTerm1, 'T00:00Z', StartTerm2),
    parse_time(StartTerm2, StartTimestamp),
    write('  スケジューリング終了日を入力 [\'YYYY-MM-DD\'.]'), nl,
    read(EndTerm1),
    string_concat(EndTerm1, 'T23:59Z', EndTerm2),
    parse_time(EndTerm2, EndTimeStamp),
    set_config('ScheduleFrom',StartTimestamp),
    set_config('ScheduleTo',EndTimeStamp),
    cls, location(1,1), my_main(3).

% スケジュール初期化
reset_schedule :-
    clear,
    cls, location(1,1), my_main(4).
    

% スケジューリング
do_schedule :-
    cls,
    solve_csp,
    apply_schedule,
    cls, location(1,1), my_main(5).

wstr(1,'Mon').
wstr(2,'Tue').
wstr(3,'Wed').
wstr(4,'Thu').
wstr(5,'Fri').
wstr(6,'Sat').
wstr(7,'Sun').
    
% スケジュール表示
print_schedule :-
    write('スケジュール'), nl,
    write('    戻る'), nl,
    forall(day(Y,M,D,W),(
	       write('---------------------------------------------------------------'),nl,
	       print_schedule(Y,M,D,W)
	  )),
    write('---------------------------------------------------------------'),nl,
    symbol(2,1),
    input('print',2,1).
print_schedule(Y,M,D,W) :-
    findall(schedule(date(Y,M,D,H,I,S,X1,X2,X3),Tid,Fixed),schedule(date(Y,M,D,H,I,S,X1,X2,X3),Tid,Fixed),Schedules),
    left(100),
    wstr(W,Wstr),writef('%t-%t-%t (%t)',[Y,M,D,Wstr]),nl,
    print_schedule(Schedules).
print_schedule([]) :- !.
print_schedule([Sc|Rest]) :-
    Sc = schedule(date(Y,M,D,H,I,S,_,_,_),Tid,Fixed),
    task(Tid,Description,ETP,_,_),
    date_time_stamp(date(Y,M,D,H,I,S,0,-,-),ST),
    ET is ST + ETP*60,
    stamp_to_time(ET,EH,EI,_),
    writef('    ',[]),print_time(H,I), write('-'), print_time(EH,EI),
    writef(': (%t) %t',[Tid,Description]),
    (Fixed, write(' (fixed)'), !; true), nl,
    print_schedule(Rest).
print_time(H,I) :-
    (H / 10 < 1, !, write('0'), write(H); write(H)),
    write(':'),
    (I / 10 < 1, !, write('0'), write(I); write(I)).

proc('print', 2) :- !, cls, location(1,1), my_main(6).

% 終わり
end :- save, !.

% go
go :- load, cls, location(1,1), prepare, my_main, !.
go :- write('異常終了.'), !.
