export interface StatsProps {
  totalFastCompleted: number
  totalHoursFasted: number

  card: string
  text: string
  subText: string

  onBack: () => void
}

@Builder
export function StatsPage(p: StatsProps) {
  Scroll() {
    Column({ space: 12 }) {
      Row() {
        Button('Back')
          .width(70).height(30)
          .backgroundColor(p.card)
          .fontColor(p.text)
          .onClick(() => p.onBack())
      }
      .width('92%')
      .margin({ top: 8 })

      Text('Your Stats')
        .fontSize(18).fontColor(p.text).fontWeight(FontWeight.Bolder)

      Column() {
        Row() {
          Text('Completed Fasts:')
            .fontSize(14).fontColor(p.subText)
          Blank()
          Text(`${p.totalFastCompleted}`)
            .fontSize(16).fontColor(p.text).fontWeight(FontWeight.Bold)
        }
        .margin({ bottom: 8 })

        Row() {
          Text('Total Hours Fasted:')
            .fontSize(14).fontColor(p.subText)
          Blank()
          Text(`${Math.round(p.totalHoursFasted)}`)
            .fontSize(16).fontColor(p.text).fontWeight(FontWeight.Bold)
        }
      }
      .width('92%')
      .padding(12)
      .backgroundColor(p.card)
      .borderRadius(12)

      Text('Tips: Keep your hydration up and try to be consistent with your eating window.')
        .fontSize(12).fontColor(p.subText)
        .margin({ top: 8 })
    }
    .width('100%')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center)
    .padding({ bottom: 60 })
  }
  .width('100%').height('100%')
}
