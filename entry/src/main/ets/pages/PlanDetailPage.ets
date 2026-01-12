export interface PlanDetailProps {
  selectedPlan: string
  waterReminderActive: boolean
  fastingStart: number
  fastingEnd: number
  remainingTime: string
  isFastingActive: boolean
  currentQuote: string
  waterIntake: number
  dailyWaterGoal: number

  card: string
  primary: string
  text: string
  subText: string

  onBack: () => void
  onGoStats: () => void
  onStartStop: () => Promise<void>
  onReset: () => Promise<void>
  onShowTip: () => void

  onWaterMinus: () => Promise<void>
  onWaterPlus: () => Promise<void>
  onGoalMinus: () => Promise<void>
  onGoalPlus: () => Promise<void>
}

@Builder
export function PlanDetailPage(p: PlanDetailProps) {
  Scroll() {
    Column({ space: 12 }) {
      // Top bar
      Row() {
        Button('Back')
          .width(70).height(30)
          .fontSize(15)
          .backgroundColor(p.card)
          .fontColor(p.text)
          .onClick(() => { p.onBack() })

        Blank()

        Button('📊')
          .width(50).height(30)
          .backgroundColor(p.card)
          .fontColor(p.text)
          .onClick(() => p.onGoStats())
      }
      .width('92%')
      .margin({ top: 8 })

      // Header
      Column() {
        Text(`Plan: ${p.selectedPlan || '-'}`)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(p.text)
          .textAlign(TextAlign.Center)

        if (p.waterReminderActive) {
          Text('💧 Water Reminder: ON')
            .fontSize(12)
            .fontColor('#00BFFF')
            .margin({ top: 4 })
        } else {
          Text('💧 Water Reminder: OFF')
            .fontSize(12)
            .fontColor(p.subText)
            .margin({ top: 4 })
        }
      }
      .width('92%')
      .padding(12)
      .backgroundColor(p.card)
      .borderRadius(12)

      // Times
      Column() {
        Row() {
          Column() {
            Text('Start')
              .fontSize(12).fontColor(p.subText)
              .margin({ bottom: 2 })
            Text(p.fastingStart ? new Date(p.fastingStart).toLocaleTimeString() : 'Not started')
              .fontSize(14).fontColor(p.text).fontWeight(FontWeight.Medium)
          }
          .margin({ right: 60, top: 0 })

          Column() {
            Text('End')
              .fontSize(12).fontColor(p.subText)
              .margin({ bottom: 2 })
            Text(p.fastingEnd ? new Date(p.fastingEnd).toLocaleTimeString() : 'Not set')
              .fontSize(14).fontColor(p.text).fontWeight(FontWeight.Medium)
          }
        }
        .justifyContent(FlexAlign.SpaceBetween)
        .width('92%')

        Column() {
          Text('Remaining Time')
            .fontSize(12).fontColor(p.subText)
            .margin({ top: 8, bottom: 6 })
          Text(p.remainingTime)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(p.primary)
        }
        .width('92%')
      }

      // Controls
      Row() {
        Button(p.isFastingActive ? 'Stop' : 'Start')
          .width(100).height(38)
          .backgroundColor(p.isFastingActive ? '#FF3B30' : p.primary)
          .fontColor(Color.White)
          .onClick(async () => {
            await p.onStartStop()
          })

        Button('Reset')
          .width(90).height(38)
          .backgroundColor('#8E8E93')
          .fontColor(Color.White)
          .margin({ left: 10 })
          .onClick(async () => {
            await p.onReset()
          })

        Button('Show Tip')
          .width(100).height(38)
          .backgroundColor(p.card)
          .fontColor(p.text)
          .margin({ left: 10 })
          .onClick(() => p.onShowTip())
      }
      .width('92%')

      if (p.currentQuote.length > 0) {
        Text(p.currentQuote)
          .fontSize(12)
          .fontColor(p.subText)
          .textAlign(TextAlign.Center)
          .margin({ top: 4 })
      }

      // ---- Water Intake Card ----
      Column() {
        Text('Water Intake')
          .fontSize(14).fontColor(p.text).fontWeight(FontWeight.Bold)

        Text(`Progress: ${Math.floor(
          Math.max(0, Math.min(1,
            p.dailyWaterGoal > 0 ? p.waterIntake / p.dailyWaterGoal : 0
          )) * 100
        )}%`)
          .fontSize(12)
          .fontColor(p.subText)

        Row() {
          Button('-')
            .width(36).height(34)
            .backgroundColor(p.card)
            .fontColor(p.text)
            .onClick(async () => {
              await p.onWaterMinus()
            })

          Text(`${p.waterIntake}/${p.dailyWaterGoal} cups`)
            .fontSize(14).fontColor(p.text)
            .margin({ left: 10, right: 10 })

          Button('+')
            .width(36).height(34)
            .backgroundColor(p.primary)
            .fontColor(Color.White)
            .onClick(async () => {
              await p.onWaterPlus()
            })
        }
        .margin({ bottom: 6 })

        // Goal line
        Row() {
          Text('Daily Goal:')
            .fontSize(12).fontColor(p.subText)
          Button('-')
            .width(30).height(30)
            .backgroundColor(p.card)
            .fontColor(p.text)
            .margin({ left: 8 })
            .onClick(async () => {
              await p.onGoalMinus()
            })
          Text(`${p.dailyWaterGoal}`)
            .fontSize(14).fontColor(p.text)
            .margin({ left: 6, right: 6 })
          Button('+')
            .width(30).height(30)
            .backgroundColor(p.primary)
            .fontColor(Color.White)
            .onClick(async () => {
              await p.onGoalPlus()
            })
        }

        Text(p.waterReminderActive ? 'Hourly reminder: ON' : 'Hourly reminder: OFF')
          .fontSize(12).fontColor(p.subText)
          .margin({ top: 8 })
      }
      .width('92%')
      .padding(12)
      .backgroundColor(p.card)
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
