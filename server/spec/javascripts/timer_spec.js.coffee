class TimerTestHelpers
  isTimerActiveAt: (timer_data, at) ->
    timer_json = JSON.parse JSON.stringify timer_data
    timer = new Iivari.Models.Timer(timer_json)
    return timer.isActive(at)

describe 'timer-parser', ->

  timer_data = {
    type: 'poweroff',
    start_date: "2011/06/20", end_date: "2011/06/25",
    start_at: "12:00", end_at: "04:04"
  }

  it 'should parse properly', ->
    timer_json = JSON.parse JSON.stringify timer_data
    timer = new Iivari.Models.Timer(timer_json)
    expect(timer.start_date).toEqual new Date "2011/06/20"
    expect(timer.end_date).toEqual new Date "2011/06/25"
    expect(timer.start_time).toEqual 720
    expect(timer.end_time).toEqual 244
    expect(timer.description).toEqual "poweroff on 2011-6-20 - 2011-6-25 at 12:00 - 04:04"
    expect(timer.type).toEqual "poweroff"


# day shift is when start_time < end_time
describe 'timer-day-shift', ->

  timer_data = {
    type: 'poweroff',
    start_date: "2010/08/01", end_date: "2011/05/31",
    start_at: "07:00", end_at: "18:00"
  }

  it 'should not be active before period', ->
    at = new Date(2010,6,31)
    expect(TimerTestHelpers::isTimerActiveAt(timer_data, at)).toEqual false

  it 'should not be active before start_time at first day of period', ->
    at = new Date(2010,7,1,6,59)
    expect(TimerTestHelpers::isTimerActiveAt(timer_data, at)).toEqual false

  it 'should be active after start_time at first day of period', ->
    at = new Date(2010,7,1,7,1)
    expect(TimerTestHelpers::isTimerActiveAt(timer_data, at)).toEqual true

  it 'should not be active after end_time', ->
    at = new Date(2010,7,1,18,1)
    expect(TimerTestHelpers::isTimerActiveAt(timer_data, at)).toEqual false

  it 'should not be active between end_time and start_time', ->
    at = new Date(2011,7,2,6,59)
    expect(TimerTestHelpers::isTimerActiveAt(timer_data, at)).toEqual false

  it 'should be active during cycle', ->
    at = new Date(2011,1,1,14,0)
    expect(TimerTestHelpers::isTimerActiveAt(timer_data, at)).toEqual true

  it 'should be active the last day of period properly', ->
    at = new Date(2011,4,31,7,0)
    expect(TimerTestHelpers::isTimerActiveAt(timer_data, at)).toEqual true

  it 'should be active at the last minute of the last day of the period', ->
    at = new Date(2011,4,31,18,0)
    expect(TimerTestHelpers::isTimerActiveAt(timer_data, at)).toEqual true

  it 'should not be active after end_time of the last day of the period', ->
    at = new Date(2011,4,31,18,1)
    expect(TimerTestHelpers::isTimerActiveAt(timer_data, at)).toEqual false

  it 'should not be active after period', ->
    at = new Date(2011,5,1,12,30)
    expect(TimerTestHelpers::isTimerActiveAt(timer_data, at)).toEqual false


# night shift is when end_time < start_time
describe 'timer-night-shift', ->

  timer_data = {
    type: 'poweroff',
    start_date: "2011/06/20", end_date: "2011/06/25",
    start_at: "12:00", end_at: "04:04"
  }

  it 'should not be active before period', ->
    at = new Date(2011,5,19,14,0)
    expect(TimerTestHelpers::isTimerActiveAt(timer_data, at)).toEqual false

  it 'should not be active before start_time at first day of period', ->
    at = new Date(2011,5,20,11,59)
    expect(TimerTestHelpers::isTimerActiveAt(timer_data, at)).toEqual false

  it 'should be active after start_time at first day of period', ->
    at = new Date(2011,5,20,12,0)
    expect(TimerTestHelpers::isTimerActiveAt(timer_data, at)).toEqual true

  it 'should be active through midnight at night shift', ->
    at = new Date(2011,5,20,23,59)
    expect(TimerTestHelpers::isTimerActiveAt(timer_data, at)).toEqual true

  it 'should be active in the morning', ->
    at = new Date(2011,5,21,4,4)
    expect(TimerTestHelpers::isTimerActiveAt(timer_data, at)).toEqual true

  it 'should not be active after end_time', ->
    at = new Date(2011,5,21,4,5)
    expect(TimerTestHelpers::isTimerActiveAt(timer_data, at)).toEqual false

  it 'should be active after 12:00', ->
    at = new Date(2011,5,21,14,4)
    expect(TimerTestHelpers::isTimerActiveAt(timer_data, at)).toEqual true

  it 'should be active at the last minute of the last day of the period', ->
    at = new Date(2011,5,25,4,4)
    expect(TimerTestHelpers::isTimerActiveAt(timer_data, at)).toEqual true

  it 'should not be active after end_time of the last day of the period', ->
    at = new Date(2011,5,25,4,5)
    expect(TimerTestHelpers::isTimerActiveAt(timer_data, at)).toEqual false

  it 'should not be active after period', ->
    at = new Date(2011,5,25,12,30)
    expect(TimerTestHelpers::isTimerActiveAt(timer_data, at)).toEqual false


describe 'refresh-timer', ->

  timer_data = {
    type: 'refresh',
    start_date: "2011/07/01", end_date: "2011/07/31",
    start_at: "12:00"
  }

  it 'should parse properly', ->
    timer_json = JSON.parse JSON.stringify timer_data
    timer = new Iivari.Models.Timer(timer_json)
    expect(timer.description).toEqual "refresh on 2011-7-1 - 2011-7-31 at 12:00"
    expect(timer.start_time).toEqual 720
    expect(timer.end_time).toEqual 730
    expect(timer.type).toEqual "refresh"

  it 'should not be active before', ->
    at = new Date(2011,6,2,11,59)
    expect(TimerTestHelpers::isTimerActiveAt(timer_data, at)).toEqual false

  it 'should be active at', ->
    at = new Date(2011,6,2,12,0)
    expect(TimerTestHelpers::isTimerActiveAt(timer_data, at)).toEqual true

  it 'should be active at t+10 min', ->
    at = new Date(2011,6,2,12,10)
    expect(TimerTestHelpers::isTimerActiveAt(timer_data, at)).toEqual true

  it 'should not be active at t+11 min', ->
    at = new Date(2011,6,2,12,11)
    expect(TimerTestHelpers::isTimerActiveAt(timer_data, at)).toEqual false


# check that time range 00:00 - 23:59 does not flicker at midnight
describe 'display-off-all-day-long', ->

  timer_data = {
    type: 'poweroff',
    start_date: "2011/07/01", end_date: "2011/07/03",
    start_at: "00:00", end_at: "23:59"
  }

  it 'should be active all day long', ->
    at = new Date(2011,6,2,0,0)
    expect(TimerTestHelpers::isTimerActiveAt(timer_data, at)).toEqual true

    at = new Date(2011,6,2,12,0)
    expect(TimerTestHelpers::isTimerActiveAt(timer_data, at)).toEqual true

    at = new Date(2011,6,2,23,59)
    expect(TimerTestHelpers::isTimerActiveAt(timer_data, at)).toEqual true


# check that refresh timer without start_at time does not trigger ever
describe 'display-refresh-but-dont-know-when', ->

  timer_data = {
    type: 'refresh',
    start_date: "2011/07/01", end_date: "2011/07/03",
    start_at: null
  }

  it 'should not be active ever', ->
    at = new Date(2011,6,2,0,0)
    expect(TimerTestHelpers::isTimerActiveAt(timer_data, at)).toEqual false

    at = new Date(2011,6,2,12,0)
    expect(TimerTestHelpers::isTimerActiveAt(timer_data, at)).toEqual false

    at = new Date(2011,6,2,23,59)
    expect(TimerTestHelpers::isTimerActiveAt(timer_data, at)).toEqual false
