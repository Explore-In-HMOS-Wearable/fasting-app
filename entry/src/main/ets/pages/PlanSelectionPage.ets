export interface PlanSelectionProps {
  selectedPlan: string
  fastingEnd: number
  remainingTime: string
  isFastingActive: boolean
  currentQuote: string

  darkMode: boolean
  bg: string
  card: string
  primary: string
  text: string
  subText: string

  onSelectPlan: (plan: string, hours: number) => Promise<void>
  onContinueCurrent: () => void
  onClearAll: () => Promise<void>
  onViewStats: () => void
}

@Builder
export function PlanSelectionPage(p: PlanSelectionProps) {
  Scroll() {
    Column({ space: 14 }) {
      if (p.selectedPlan && p.fastingEnd > 0) {
        Text('Fasting Ongoing')
          .fontSize(18)
          .fontWeight(FontWeight.Bolder)
          .fontColor(p.text)
          .textAlign(TextAlign.Center)
          .margin({ top: 12, bottom: 8 })
      } else {
        Text('Choose Your\nFasting Plan')
          .fontSize(18)
          .fontWeight(FontWeight.Bolder)
          .fontColor(p.text)
          .textAlign(TextAlign.Center)
          .margin({ top: 12, bottom: 8 })
      }

      // Current Plan
      if (p.selectedPlan && p.fastingEnd > 0) {
        Column() {
          Text('Current Plan')
            .fontSize(13)
            .fontColor(p.subText)
            .margin({ bottom: 4 })
          Text(`${p.selectedPlan} • ${p.remainingTime}`)
            .fontSize(16)
            .fontColor(p.primary)
            .fontWeight(FontWeight.Medium)
          Text(p.isFastingActive ? '⏱️ Active' : '⏸️ Paused')
            .fontSize(12)
            .fontColor(p.isFastingActive ? '#34C759' : '#FF9500')
            .margin({ top: 2 })
        }
        .width('92%')
        .padding(12)
        .backgroundColor(p.card)
        .borderRadius(12)
        .margin({ top: 4, bottom: 10 })
      }

      if (!(p.selectedPlan && p.fastingEnd > 0)) {
        Column({ space: 8 }) {
          Button('16/8 Plan')
            .width(180).height(44)
            .backgroundColor(p.primary)
            .fontColor(Color.White)
            .onClick(async () => {
              await p.onSelectPlan('16/8', 16)
            })

          Button('18/6 Plan')
            .width(180).height(44)
            .backgroundColor(p.primary)
            .fontColor(Color.White)
            .onClick(async () => {
              await p.onSelectPlan('18/6', 18)
            })

          Button('20/4 Plan')
            .width(180).height(44)
            .backgroundColor(p.primary)
            .fontColor(Color.White)
            .onClick(async () => {
              await p.onSelectPlan('20/4', 20)
            })
        }
        .margin({ top: 4, bottom: 6 })
      }

      if (p.selectedPlan && p.fastingEnd > 0) {
        Button('Continue Current Plan')
          .width(220).height(44)
          .backgroundColor('#34C759')
          .fontColor(Color.White)
          .onClick(() => { p.onContinueCurrent() })
          .margin({ top: 4 })

        Button('Clear All')
          .width(160).height(42)
          .backgroundColor('#808080')
          .fontColor(Color.White)
          .margin({ top: 8 })
          .onClick(async () => {
            await p.onClearAll()
          })
      }

      Button('View Stats')
        .width(160).height(42)
        .backgroundColor(p.card)
        .fontColor(p.text)
        .margin({ top: 0 })
        .onClick(() => p.onViewStats())

      if (p.currentQuote.length > 0) {
        Text(p.currentQuote)
          .fontSize(12).fontColor(p.subText)
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
  .safeAreaPadding({ bottom: 40 })
}
