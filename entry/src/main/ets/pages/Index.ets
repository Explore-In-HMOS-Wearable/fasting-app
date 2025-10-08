import preferences from '@ohos.data.preferences';
import notificationManager from '@ohos.notificationManager';
import promptAction from '@ohos.promptAction';

const PREF_NAME = 'fastingApp';
const NOTIFICATION_ID = 1001;

type PageName = 'planSelection' | 'planDetail' | 'stats';

@Entry
@Component
struct Index {

  // --------- UI/Navigation ---------
  @State showWelcome: boolean = true
  @State currentPage: PageName = 'planSelection'
  @State darkMode: boolean = true

  // --------- Plan / Fasting ---------
  @State selectedPlan: string = ''
  @State fastingStart: number = 0
  @State fastingEnd: number = 0
  @State remainingTime: string = ''
  @State isFastingActive: boolean = false
  @State timerTrigger: boolean = false
  @State notificationSent: boolean = false

  // --------- Water Reminder / Intake ---------
  @State waterReminderActive: boolean = false
  @State lastWaterReminder: number = 0
  @State waterIntake: number = 0
  @State dailyWaterGoal: number = 8
  @State waterTestNow: boolean = false

  // --------- Motivation Sentences ---------
  private motivationalQuotes: string[] = [
    "Stay strong, you're doing great!",
    "Drink some water and keep going!",
    "Every second counts towards your health!",
    "Discipline equals freedom!",
    "One step at a time.",
    "Focus on the process,\n not the outcome."
  ]
  @State currentQuote: string = ''

  @State totalFastCompleted: number = 0
  @State totalHoursFasted: number = 0

  // --------- Timer ---------
  private timer: number = 0

  // --------- Welcome Splash ---------
  @State scaleValue: number = 1
  @State opacityValue: number = 1

  async aboutToAppear() {
    await this.loadFastingData()
    setTimeout(() => { this.showWelcome = false }, 1750);
  }

  aboutToDisappear(): void {
    clearInterval(this.timer)
  }

  // ---------- THEME HELPERS ----------
  private bg(): string { return this.darkMode ? '#0E1116' : '#F7F7F7' }
  private card(): string { return this.darkMode ? '#1B2533' : '#FFFFFF' }
  private primary(): string { return '#007DFF' }
  private text(): string { return this.darkMode ? '#FFFFFF' : '#111111' }
  private subText(): string { return this.darkMode ? '#B7C2D0' : '#555555' }

  build() {
    Column() {
      // App bar
      if (!this.showWelcome) {
        Row() {
          Text('')
            .fontSize(13)
            .fontWeight(FontWeight.Bolder)
            .fontColor(this.text())
            .margin({left:20})
          Blank()
          Button(this.darkMode ? 'Sun' : 'Dark')
            .width(44).height(34)
            .backgroundColor(this.card())
            .fontColor(this.text())
            .margin({right:28})
            .onClick(async () => {
              this.darkMode = !this.darkMode
              await this.saveFastingData()
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        .backgroundColor(this.bg())
      }

      if (this.showWelcome) {
        Column() {
          Text('Fasting App')
            .fontSize(28)
            .fontWeight(FontWeight.Bolder)
            .fontColor(Color.Orange)
        }
        .width('100%').height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor(this.bg())
      } else if (this.currentPage === 'planSelection') {
        this.PlanSelectionPage()
      } else if (this.currentPage === 'planDetail') {
        this.PlanDetailPage()
      } else {
        this.StatsPage()
      }
    }
    .width('100%').height('100%')
    .backgroundColor(this.bg())
  }

  // ---------- Plan Selection ----------
  @Builder
  PlanSelectionPage() {
    Scroll() {
      Column({ space: 14 }) {
        if (this.selectedPlan && this.fastingEnd > 0) {
          Text('Fasting Ongoing')
            .fontSize(18)
            .fontWeight(FontWeight.Bolder)
            .fontColor(this.text())
            .textAlign(TextAlign.Center)
            .margin({ top: 12, bottom: 8 })
        } else {
          Text('Choose Your\nFasting Plan')
            .fontSize(18)
            .fontWeight(FontWeight.Bolder)
            .fontColor(this.text())
            .textAlign(TextAlign.Center)
            .margin({ top: 12, bottom: 8 })
        }

        // Current Plan
        if (this.selectedPlan && this.fastingEnd > 0) {
          Column() {
            Text('Current Plan')
              .fontSize(13)
              .fontColor(this.subText())
              .margin({ bottom: 4 })
            Text(`${this.selectedPlan} • ${this.remainingTime}`)
              .fontSize(16)
              .fontColor(this.primary())
              .fontWeight(FontWeight.Medium)
            Text(this.isFastingActive ? '⏱️ Active' : '⏸️ Paused')
              .fontSize(12)
              .fontColor(this.isFastingActive ? '#34C759' : '#FF9500')
              .margin({ top: 2 })
          }
          .width('92%')
          .padding(12)
          .backgroundColor(this.card())
          .borderRadius(12)
          .margin({ top: 4, bottom: 10 })
        }

        if (!(this.selectedPlan && this.fastingEnd > 0)) {
          Column({ space: 8 }) {
            Button('16/8 Plan')
              .width(180).height(44)
              .backgroundColor(this.primary())
              .fontColor(Color.White)
              .onClick(async () => {
                await this.handlePlanSelection('16/8', 16)
              })

            Button('18/6 Plan')
              .width(180).height(44)
              .backgroundColor(this.primary())
              .fontColor(Color.White)
              .onClick(async () => {
                await this.handlePlanSelection('18/6', 18)
              })

            Button('20/4 Plan')
              .width(180).height(44)
              .backgroundColor(this.primary())
              .fontColor(Color.White)
              .onClick(async () => {
                await this.handlePlanSelection('20/4', 20)
              })
          }
          .margin({ top: 4, bottom: 6 })
        }

        if (this.selectedPlan && this.fastingEnd > 0) {
          Button('Continue Current Plan')
            .width(220).height(44)
            .backgroundColor('#34C759')
            .fontColor(Color.White)
            .onClick(() => { this.currentPage = 'planDetail' })
            .margin({ top: 4 })

          Button('Clear All')
            .width(160).height(42)
            .backgroundColor('#808080')
            .fontColor(Color.White)
            .margin({ top: 8 })
            .onClick(async () => {
              this.resetFasting();
              await this.saveFastingData();
            })
        }

        Button('View Stats')
          .width(160).height(42)
          .backgroundColor(this.card())
          .fontColor(this.text())
          .margin({ top: 0 })
          .onClick(() => this.currentPage = 'stats')

        if (this.currentQuote.length > 0) {
          Text(this.currentQuote)
            .fontSize(12).fontColor(this.subText())
            .textAlign(TextAlign.Center)
            .margin({ top: 12 })
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .padding({ bottom: 60 })
    }
    .width('100%').height('100%')
    .safeAreaPadding({bottom: 40})
  }

  // ---------- Plan Detail ----------
  @Builder
  PlanDetailPage() {
    Scroll() {
      Column({ space: 12 }) {
        // Top bar
        Row() {
          Button('Back')
            .width(70).height(30)
            .fontSize(15)
            .backgroundColor(this.card())
            .fontColor(this.text())
            .onClick(() => { this.currentPage = 'planSelection' })

          Blank()

          Button('📊')
            .width(50).height(30)
            .backgroundColor(this.card())
            .fontColor(this.text())
            .onClick(() => this.currentPage = 'stats')
        }
        .width('92%')
        .margin({ top: 8 })

        // Header
        Column() {
          Text(`Plan: ${this.selectedPlan || '-'}`)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.text())
            .textAlign(TextAlign.Center)

          if (this.waterReminderActive) {
            Text('💧 Water Reminder: ON')
              .fontSize(12)
              .fontColor('#00BFFF')
              .margin({ top: 4 })
          } else {
            Text('💧 Water Reminder: OFF')
              .fontSize(12)
              .fontColor(this.subText())
              .margin({ top: 4 })
          }
        }
        .width('92%')
        .padding(12)
        .backgroundColor(this.card())
        .borderRadius(12)

        // Times
        Column() {
          Row() {
            Column() {
              Text('Start')
                .fontSize(12).fontColor(this.subText())
                .margin({ bottom: 2 })
              Text(this.fastingStart ? new Date(this.fastingStart).toLocaleTimeString() : 'Not started')
                .fontSize(14).fontColor(this.text()).fontWeight(FontWeight.Medium)
            }
            .margin({ right: 60, top: 0 })

            Column() {
              Text('End')
                .fontSize(12).fontColor(this.subText())
                .margin({ bottom: 2 })
              Text(this.fastingEnd ? new Date(this.fastingEnd).toLocaleTimeString() : 'Not set')
                .fontSize(14).fontColor(this.text()).fontWeight(FontWeight.Medium)
            }
          }
          .justifyContent(FlexAlign.SpaceBetween)
          .width('92%')

          Column() {
            Text('Remaining Time')
              .fontSize(12).fontColor(this.subText())
              .margin({ top: 8, bottom: 6 })
            Text(this.remainingTime)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.primary())
          }
          .width('92%')
        }

        // Controls
        Row() {
          Button(this.isFastingActive ? 'Stop' : 'Start')
            .width(100).height(38)
            .backgroundColor(this.isFastingActive ? '#FF3B30' : this.primary())
            .fontColor(Color.White)
            .onClick(async () => {
              if (this.isFastingActive) { this.stopFasting() } else { this.runTimer() }
              await this.saveFastingData()
            })

          Button('Reset')
            .width(90).height(38)
            .backgroundColor('#8E8E93')
            .fontColor(Color.White)
            .margin({ left: 10 })
            .onClick(async () => {
              this.resetFasting()
              await this.saveFastingData()
            })

          Button('Show Tip')
            .width(100).height(38)
            .backgroundColor(this.card())
            .fontColor(this.text())
            .margin({ left: 10 })
            .onClick(() => this.showRandomQuote())
        }
        .width('92%')

        if (this.currentQuote.length > 0) {
          Text(this.currentQuote)
            .fontSize(12)
            .fontColor(this.subText())
            .textAlign(TextAlign.Center)
            .margin({ top: 4 })
        }

        // ---- Water Intake Card ----
        Column() {
          Text('Water Intake')
            .fontSize(14).fontColor(this.text()).fontWeight(FontWeight.Bold)

          Text(`Progress: ${Math.floor(
            Math.max(0, Math.min(1,
              this.dailyWaterGoal > 0 ? this.waterIntake / this.dailyWaterGoal : 0
            )) * 100
          )}%`)
            .fontSize(12)
            .fontColor(this.subText())

          Row() {
            Button('-')
              .width(36).height(34)
              .backgroundColor(this.card())
              .fontColor(this.text())
              .onClick(async () => {
                if (this.waterIntake > 0) { this.waterIntake -= 1; await this.saveFastingData() }
              })

            Text(`${this.waterIntake}/${this.dailyWaterGoal} cups`)
              .fontSize(14).fontColor(this.text())
              .margin({ left: 10, right: 10 })

            Button('+')
              .width(36).height(34)
              .backgroundColor(this.primary())
              .fontColor(Color.White)
              .onClick(async () => {
                this.waterIntake += 1
                await this.saveFastingData()
              })
          }
          .margin({ bottom: 6 })

          // Goal line
          Row() {
            Text('Daily Goal:')
              .fontSize(12).fontColor(this.subText())
            Button('-')
              .width(30).height(30)
              .backgroundColor(this.card())
              .fontColor(this.text())
              .margin({ left: 8 })
              .onClick(async () => {
                if (this.dailyWaterGoal > 4) { this.dailyWaterGoal -= 1; await this.saveFastingData() }
              })
            Text(`${this.dailyWaterGoal}`)
              .fontSize(14).fontColor(this.text())
              .margin({ left: 6, right: 6 })
            Button('+')
              .width(30).height(30)
              .backgroundColor(this.primary())
              .fontColor(Color.White)
              .onClick(async () => {
                if (this.dailyWaterGoal < 20) { this.dailyWaterGoal += 1; await this.saveFastingData() }
              })
          }

          Text(this.waterReminderActive ? 'Hourly reminder: ON' : 'Hourly reminder: OFF')
            .fontSize(12).fontColor(this.subText())
            .margin({ top: 8 })
        }
        .width('92%')
        .padding(12)
        .backgroundColor(this.card())
        .borderRadius(12)
        .margin({ bottom: 14 })
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Center)
      .padding({ bottom: 60 })
    }
    .width('100%').height('100%')
  }

  // ---------- Stats Page ----------
  @Builder
  StatsPage() {
    Scroll() {
      Column({ space: 12 }) {
        Row() {
          Button('Back')
            .width(70).height(30)
            .backgroundColor(this.card())
            .fontColor(this.text())
            .onClick(() => this.currentPage = 'planSelection')
        }
        .width('92%')
        .margin({ top: 8 })

        Text('Your Stats')
          .fontSize(18).fontColor(this.text()).fontWeight(FontWeight.Bolder)

        Column() {
          Row() {
            Text('Completed Fasts:')
              .fontSize(14).fontColor(this.subText())
            Blank()
            Text(`${this.totalFastCompleted}`)
              .fontSize(16).fontColor(this.text()).fontWeight(FontWeight.Bold)
          }
          .margin({ bottom: 8 })

          Row() {
            Text('Total Hours Fasted:')
              .fontSize(14).fontColor(this.subText())
            Blank()
            Text(`${Math.round(this.totalHoursFasted)}`)
              .fontSize(16).fontColor(this.text()).fontWeight(FontWeight.Bold)
          }
        }
        .width('92%')
        .padding(12)
        .backgroundColor(this.card())
        .borderRadius(12)

        Text('Tips: Keep your hydration up and try to be consistent with your eating window.')
          .fontSize(12).fontColor(this.subText())
          .margin({ top: 8 })
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Center)
      .padding({ bottom: 60 })
    }
    .width('100%').height('100%')
  }

  // ---------- Logic ----------
  async handlePlanSelection(plan: string, hours: number) {

    if (this.selectedPlan === plan && this.fastingEnd > 0) {
      this.currentPage = 'planDetail';
      return;
    }

    if (this.selectedPlan && this.fastingEnd > 0) {
      promptAction.showDialog({
        title: 'Change Plan?',
        message: `You already have an active plan (${this.selectedPlan}). Do you want to cancel it and switch to ${plan}?`,
        buttons: [
          { text: 'No', color: '#666666' },
          { text: 'Yes', color: '#007DFF' }
        ]
      }).then(async (data) => {
        if (data.index === 1) {
          await this.askWaterReminder(plan, hours)
        }
      })
    } else {
      await this.askWaterReminder(plan, hours)
    }
  }

  async askWaterReminder(plan: string, hours: number) {
    promptAction.showDialog({
      title: 'Water Reminder',
      message: 'Would you like to receive a reminder every hour to drink water? 💧',
      buttons: [
        { text: 'No', color: '#666666' },
        { text: 'Yes', color: '#007DFF' }
      ]
    }).then(async (data) => {
      this.waterReminderActive = (data.index === 1)
      this.selectedPlan = plan
      this.startFasting(hours)
      await this.saveFastingData()
      this.currentPage = 'planDetail'
    })
  }

  startFasting(hours: number) {
    this.fastingStart = Date.now()
    this.fastingEnd = this.fastingStart + hours * 60 * 60 * 1000
    this.remainingTime = this.formatRemaining(this.fastingEnd - this.fastingStart)
    this.isFastingActive = false
    this.notificationSent = false
    this.waterIntake = 0
    this.lastWaterReminder = Date.now()
    this.showRandomQuote()
    clearInterval(this.timer)
  }

  runTimer() {
    if (this.fastingEnd <= Date.now()) {
      const hours = this.getHoursFromPlan(this.selectedPlan)
      this.startFasting(hours)
    }
    this.isFastingActive = true
    clearInterval(this.timer)
    this.updateRemaining()
    this.timer = setInterval(() => {
      this.updateRemaining()
      this.checkNotificationTime()
      this.checkWaterReminder()

      if (Math.random() < 0.03) { this.showRandomQuote() }
      this.timerTrigger = !this.timerTrigger
    }, 1000)
  }

  stopFasting() {
    this.isFastingActive = false
    clearInterval(this.timer)
  }

  resetFasting() {
    this.isFastingActive = false
    clearInterval(this.timer)
    this.fastingStart = 0
    this.fastingEnd = 0
    this.remainingTime = ''
    //this.selectedPlan = ''
    this.notificationSent = false
    this.waterReminderActive = false
    this.waterIntake = 0
    this.lastWaterReminder = 0
    this.currentQuote = ''
  }

  updateRemaining() {
    const diff = this.fastingEnd - Date.now()
    if (diff <= 0) {
      const hoursDone = (this.fastingEnd - this.fastingStart) / (1000 * 60 * 60)
      if (hoursDone > 0.1) {
        this.totalFastCompleted += 1
        this.totalHoursFasted += hoursDone
      }
      this.remainingTime = '🎉 Congrats, fasting complete!'
      this.isFastingActive = false
      clearInterval(this.timer)
      this.saveFastingData()
    } else {
      this.remainingTime = this.formatRemaining(diff)
    }
  }

  checkNotificationTime() {
    if (!this.isFastingActive || this.notificationSent) return
    const diff = this.fastingEnd - Date.now()
    const oneHourInMs = 60 * 60 * 1000
    if (diff <= oneHourInMs && diff > 0) {
      this.sendNotification()
      this.notificationSent = true
      this.saveFastingData()
    }
  }

  checkWaterReminder() {
    if (!this.waterReminderActive || !this.isFastingActive) return
    const now = Date.now()
    const interval = 60 * 60 * 1000
    if (now - this.lastWaterReminder >= interval) {
      this.sendWaterReminder()
      this.lastWaterReminder = now
    }
  }

  showRandomQuote() {
    if (this.motivationalQuotes.length === 0) return
    const idx = Math.floor(Math.random() * this.motivationalQuotes.length)
    this.currentQuote = this.motivationalQuotes[idx]
  }

  async sendNotification() {
    try {
      let request: notificationManager.NotificationRequest = {
        id: NOTIFICATION_ID,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: 'Fasting Reminder',
            text: `Your fasting will end in 1 hour! 💪`,
            additionalText: this.selectedPlan
          }
        },
        deliveryTime: Date.now()
      }
      await notificationManager.publish(request)
    } catch (error) {
      console.error('Notification Error:', error)
    }
  }

  async sendWaterReminder() {
    try {
      let request: notificationManager.NotificationRequest = {
        id: NOTIFICATION_ID + 100,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: '💧 Water Reminder',
            text: 'Time to drink a glass of water!',
            additionalText: this.selectedPlan
          }
        },
        deliveryTime: Date.now()
      }
      await notificationManager.publish(request)
    } catch (error) {
      console.error('Water Notification Error:', error)
    }
  }

  formatRemaining(ms: number): string {
    const totalSec = Math.floor(ms / 1000)
    const h = Math.floor(totalSec / 3600)
    const m = Math.floor((totalSec % 3600) / 60)
    const s = totalSec % 60
    return `${h}h ${m}m ${s}s`
  }

  getHoursFromPlan(plan: string): number {
    switch (plan) {
      case '16/8': return 16
      case '18/6': return 18
      case '20/4': return 20
      default: return 16
    }
  }

  // ---------- Persistence ----------
  async saveFastingData() {
    try {
      const ctx = getContext(this)
      const pref = await preferences.getPreferences(ctx, PREF_NAME)
      await pref.put('fastingStart', this.fastingStart)
      await pref.put('fastingEnd', this.fastingEnd)
      await pref.put('isFastingActive', this.isFastingActive)
      await pref.put('selectedPlan', this.selectedPlan)
      await pref.put('notificationSent', this.notificationSent)

      await pref.put('waterReminderActive', this.waterReminderActive)
      await pref.put('lastWaterReminder', this.lastWaterReminder)
      await pref.put('waterIntake', this.waterIntake)
      await pref.put('dailyWaterGoal', this.dailyWaterGoal)

      await pref.put('totalFastCompleted', this.totalFastCompleted)
      await pref.put('totalHoursFasted', this.totalHoursFasted)

      await pref.put('darkMode', this.darkMode)

      await pref.flush()
    } catch (error) {
      console.error('Data Save Error:', error)
    }
  }

  async loadFastingData() {
    try {
      const ctx = getContext(this)
      const pref = await preferences.getPreferences(ctx, PREF_NAME)

      this.fastingStart = Number(await pref.get('fastingStart', 0))
      this.fastingEnd = Number(await pref.get('fastingEnd', 0))
      this.isFastingActive = (await pref.get('isFastingActive', false)) as boolean
      this.selectedPlan = (await pref.get('selectedPlan', '')) as string
      this.notificationSent = (await pref.get('notificationSent', false)) as boolean

      this.waterReminderActive = (await pref.get('waterReminderActive', false)) as boolean
      this.lastWaterReminder = Number(await pref.get('lastWaterReminder', 0))
      this.waterIntake = Number(await pref.get('waterIntake', 0))
      this.dailyWaterGoal = Number(await pref.get('dailyWaterGoal', 8))

      this.totalFastCompleted = Number(await pref.get('totalFastCompleted', 0))
      this.totalHoursFasted = Number(await pref.get('totalHoursFasted', 0))

      this.darkMode = (await pref.get('darkMode', true)) as boolean

      if (this.fastingEnd > 0) {
        if (this.fastingEnd > Date.now()) {
          this.updateRemaining()
          if (this.isFastingActive) this.runTimer()
        } else if (this.isFastingActive) {
          const hoursDone = (this.fastingEnd - this.fastingStart) / (1000 * 60 * 60)
          if (hoursDone > 0.1) {
            this.totalFastCompleted += 1
            this.totalHoursFasted += hoursDone
          }
          this.remainingTime = '🎉 Congrats, fasting complete!'
          this.isFastingActive = false
          this.notificationSent = false
          await this.saveFastingData()
        } else {
          this.remainingTime = 'Completed'
        }
      }

      this.showRandomQuote()

    } catch (error) {
      console.error('Data Load Error:', error)
    }
  }
}
