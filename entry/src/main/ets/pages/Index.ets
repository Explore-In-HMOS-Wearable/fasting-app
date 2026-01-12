import { PlanSelectionPage } from './PlanSelectionPage'
import { PlanDetailPage } from './PlanDetailPage'
import { StatsPage } from './StatsPage'
import { FastingService, PageName } from '../common/FastingService'

@Entry
@Component
struct Index {
  @State showWelcome: boolean = true
  @State currentPage: PageName = 'planSelection'
  @State darkMode: boolean = true

  @State selectedPlan: string = ''
  @State fastingStart: number = 0
  @State fastingEnd: number = 0
  @State remainingTime: string = ''
  @State isFastingActive: boolean = false
  timerTrigger: boolean = false
  notificationSent: boolean = false

  @State waterReminderActive: boolean = false
  lastWaterReminder: number = 0
  @State waterIntake: number = 0
  @State dailyWaterGoal: number = 8
  waterTestNow: boolean = false

  @State currentQuote: string = ''
  @State totalFastCompleted: number = 0
  @State totalHoursFasted: number = 0

  scaleValue: number = 1
  opacityValue: number = 1

  private svc: FastingService = new FastingService()

  async aboutToAppear() {
    await this.svc.loadFastingData(this)
    setTimeout(() => { this.showWelcome = false }, 1750)
  }

  aboutToDisappear(): void {
    this.svc.clearTimer()
  }

  private bg(): string { return this.darkMode ? '#0E1116' : '#F7F7F7' }
  private card(): string { return this.darkMode ? '#1B2533' : '#FFFFFF' }
  private primary(): string { return '#007DFF' }
  private text(): string { return this.darkMode ? '#FFFFFF' : '#111111' }
  private subText(): string { return this.darkMode ? '#B7C2D0' : '#555555' }

  build() {
    Column() {
      if (!this.showWelcome) {
        Row() {
          Text('')
            .fontSize(13)
            .fontWeight(FontWeight.Bolder)
            .fontColor(this.text())
            .margin({ left: 20 })
          Blank()
          Button(this.darkMode ? 'Sun' : 'Dark')
            .width(44).height(34)
            .backgroundColor(this.card())
            .fontColor(this.text())
            .margin({ right: 28 })
            .onClick(async () => {
              this.darkMode = !this.darkMode
              await this.svc.saveFastingData(this)
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
        PlanSelectionPage({
          selectedPlan: this.selectedPlan,
          fastingEnd: this.fastingEnd,
          remainingTime: this.remainingTime,
          isFastingActive: this.isFastingActive,
          currentQuote: this.currentQuote,

          darkMode: this.darkMode,
          bg: this.bg(),
          card: this.card(),
          primary: this.primary(),
          text: this.text(),
          subText: this.subText(),

          onSelectPlan: async (plan: string, hours: number) => {
            await this.svc.handlePlanSelection(this, plan, hours)
          },
          onContinueCurrent: () => { this.currentPage = 'planDetail' },
          onClearAll: async () => {
            this.svc.resetFasting(this)
            await this.svc.saveFastingData(this)
          },
          onViewStats: () => { this.currentPage = 'stats' }
        })
      } else if (this.currentPage === 'planDetail') {
        PlanDetailPage({
          selectedPlan: this.selectedPlan,
          waterReminderActive: this.waterReminderActive,
          fastingStart: this.fastingStart,
          fastingEnd: this.fastingEnd,
          remainingTime: this.remainingTime,
          isFastingActive: this.isFastingActive,
          currentQuote: this.currentQuote,

          waterIntake: this.waterIntake,
          dailyWaterGoal: this.dailyWaterGoal,

          card: this.card(),
          primary: this.primary(),
          text: this.text(),
          subText: this.subText(),

          onBack: () => { this.currentPage = 'planSelection' },
          onGoStats: () => { this.currentPage = 'stats' },

          onStartStop: async () => {
            if (this.isFastingActive) {
              this.svc.stopFasting(this)
            }
            else {
              this.svc.runTimer(this)
            }
            await this.svc.saveFastingData(this)
          },
          onReset: async () => {
            this.svc.resetFasting(this)
            await this.svc.saveFastingData(this)
          },
          onShowTip: () => { this.svc.showRandomQuote(this) },

          onWaterMinus: async () => {
            if (this.waterIntake > 0) { this.waterIntake -= 1; await this.svc.saveFastingData(this) }
          },
          onWaterPlus: async () => {
            this.waterIntake += 1
            await this.svc.saveFastingData(this)
          },
          onGoalMinus: async () => {
            if (this.dailyWaterGoal > 4) { this.dailyWaterGoal -= 1; await this.svc.saveFastingData(this) }
          },
          onGoalPlus: async () => {
            if (this.dailyWaterGoal < 20) { this.dailyWaterGoal += 1; await this.svc.saveFastingData(this) }
          }
        })
      } else {
        StatsPage({
          totalFastCompleted: this.totalFastCompleted,
          totalHoursFasted: this.totalHoursFasted,

          card: this.card(),
          text: this.text(),
          subText: this.subText(),

          onBack: () => { this.currentPage = 'planSelection' }
        })
      }
    }
    .width('100%').height('100%')
    .backgroundColor(this.bg())
  }
}
