class DisplayMock
  powerOff: ->
  powerOn: ->
  refresh: ->


describe 'display-ctrl', ->

  # insert spy to check window.display calls
  beforeEach ->
    mock = new DisplayMock()
    spyOn mock, 'powerOff'
    spyOn mock, 'powerOn'
    spyOn mock, 'refresh'
    window.display = mock


  # helper functions
  
  pad = (number) ->
    `(number < 10 ? '0' : '') + number`
  
  human_time_at = (d) ->
    "#{pad d.getHours()}:#{pad d.getMinutes()}"
  
  human_date_at = (d) ->
    "#{d.getFullYear()}/#{d.getMonth()+1}/#{d.getDate()}"

  ctrl_with_timer_data_for_all_days = (data) ->
    timers_json = {timers: ([data] for day in [0..6])}
    ctrl = new Iivari.Models.DisplayCtrl()
    ctrl.ctrlData.json = timers_json
    return ctrl


  it 'should powerOn when no timers are set', ->
    ctrl = new Iivari.Models.DisplayCtrl()
    ctrl.ctrlData.json = {timers: []}
    ctrl.executeCtrlData()
    expect(window.display.powerOff).not.toHaveBeenCalled()
    expect(window.display.powerOn).toHaveBeenCalled()
    expect(window.display.refresh).not.toHaveBeenCalled()


  it 'should powerOff when timer is set', ->
    now = new Date()
    ten_minutes_from_now = new Date(now.getTime() + 600000)
    data = {
      type: 'poweroff',
      start_date: human_date_at(now), 
      end_date: human_date_at(now), 
      start_at: human_time_at(now),
      end_at: human_time_at(ten_minutes_from_now)
    }
    ctrl = ctrl_with_timer_data_for_all_days data
    ctrl.executeCtrlData()
    expect(window.display.powerOff).toHaveBeenCalled()
    expect(window.display.powerOn).not.toHaveBeenCalled()
    expect(window.display.refresh).not.toHaveBeenCalled()


  it 'should powerOn after timer is due', ->
    now = new Date()
    ten_minutes_before = new Date(now.getTime() - 600000)
    data = {
      type: 'poweroff',
      start_date: human_date_at(now), 
      end_date: human_date_at(now), 
      start_at: human_time_at(ten_minutes_before),
      end_at: human_time_at(now)
    }
    ctrl = ctrl_with_timer_data_for_all_days data
    ctrl.executeCtrlData()
    expect(window.display.powerOff).not.toHaveBeenCalled()
    expect(window.display.powerOn).toHaveBeenCalled()
    expect(window.display.refresh).not.toHaveBeenCalled()


  it 'should refresh', ->
    now = new Date()
    data = {
      type: 'refresh',
      start_date: human_date_at(now), 
      end_date: human_date_at(now), 
      start_at: human_time_at(now)
    }
    ctrl = ctrl_with_timer_data_for_all_days data
    ctrl.executeCtrlData()
    expect(window.display.refresh).toHaveBeenCalled()


  it 'should not refresh when start_at is in the future', ->
    now = new Date()
    ten_minutes_from_now = new Date(now.getTime() + 600000)
    data = {
      type: 'refresh',
      start_date: human_date_at(now), 
      end_date: human_date_at(now), 
      start_at: human_time_at(ten_minutes_from_now)
    }
    ctrl = ctrl_with_timer_data_for_all_days data
    ctrl.executeCtrlData()
    expect(window.display.refresh).not.toHaveBeenCalled()


  it 'should not refresh when start_at is in the past', ->
    now = new Date()
    ten_minutes_before = new Date(now.getTime() - 600000)
    data = {
      type: 'refresh',
      start_date: human_date_at(now), 
      end_date: human_date_at(now), 
      start_at: human_time_at(ten_minutes_before)
    }
    ctrl = ctrl_with_timer_data_for_all_days data
    ctrl.executeCtrlData()
    expect(window.display.refresh).not.toHaveBeenCalled()


  # check that powerOn timer overruns otherwise effective powerOff
  it 'should be active when powerOn timer overlaps powerOff', ->
    now = new Date()
    yesterday = new Date(now.getTime() - 86400000)
    tomorrow = new Date(now.getTime() + 86400000)

    powerOff_timer = {
      type: 'poweroff',
      start_date: human_date_at(yesterday), 
      end_date: human_date_at(tomorrow), 
      start_at: "00:00",
      end_at: "23:59"
    }
    
    # assert poweroff was defined properly
    _timers = [ powerOff_timer ]
    timers_json = {timers: (_timers for day in [0..6])}
    ctrl = new Iivari.Models.DisplayCtrl()
    ctrl.ctrlData.json = timers_json
    ctrl.executeCtrlData()
    expect(window.display.powerOff).toHaveBeenCalled()
    window.display.powerOff.reset() # reset spy

    # ok, display powers off, now define exception
    powerOn_timer = {
      type: 'poweron',
      start_date: human_date_at(now), 
      end_date: human_date_at(now), 
      start_at: "00:00",
      end_at: "23:59"
    }
    _timers.push powerOn_timer
    timers_json = {timers: (_timers for day in [0..6])}
    ctrl.ctrlData.json = timers_json
    ctrl.executeCtrlData()
    expect(window.display.powerOff).not.toHaveBeenCalled()

