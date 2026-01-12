import preferences from '@ohos.data.preferences'
import notificationManager from '@ohos.notificationManager'
import common from '@ohos.app.ability.common'
import { cryptoFramework } from '@kit.CryptoArchitectureKit';


const PREF_NAME = 'fasting-app'
const NOTIFICATION_ID = 1001;


export type PageName = 'planSelection' | 'planDetail' | 'stats'

export interface FastingVm {
  getUIContext(): UIContext

  currentPage: PageName
  darkMode: boolean

  selectedPlan: string
  fastingStart: number
  fastingEnd: number
  remainingTime: string
  isFastingActive: boolean
  timerTrigger: boolean
  notificationSent: boolean

  waterReminderActive: boolean
  lastWaterReminder: number
  waterIntake: number
  dailyWaterGoal: number

  currentQuote: string
  totalFastCompleted: number
  totalHoursFasted: number
}

interface DialogResult {
  index: number
}

export class FastingService {
  private timer: number = 0

  private motivationalQuotes: string[] = [
    'Stay strong,you doing great!',
    'Drink some water and keep going!',
    'Every second counts towards your health!',
    'Discipline equals freedom!',
    'One step at a time.',
    'Focus on the process,\n not the outcome.'
  ]

  clearTimer(): void {
    clearInterval(this.timer)
  }


  async handlePlanSelection(vm: FastingVm, plan: string, hours: number): Promise<void> {
    if (vm.selectedPlan === plan && vm.fastingEnd > 0) {
      vm.currentPage = 'planDetail'
      return
    }

    if (vm.selectedPlan && vm.fastingEnd > 0) {
      try {
        const data = await vm.getUIContext().getPromptAction().showDialog({
          title: 'Change Plan?',
          message: `You already have an active plan (${vm.selectedPlan}). Do you want to cancel it and switch to ${plan}?`,
          buttons: [
            { text: 'No', color: '#666666' },
            { text: 'Yes', color: '#007DFF' }
          ]
        }) as DialogResult

        if (data.index === 1) {
          await this.askWaterReminder(vm, plan, hours)
        }
      } catch (e) {
        console.error('showDialog failed:', e)
      }
      return
    }

    await this.askWaterReminder(vm, plan, hours)
  }

  async askWaterReminder(vm: FastingVm, plan: string, hours: number): Promise<void> {
    try {
      const data = await vm.getUIContext().getPromptAction().showDialog({
        title: 'Water Reminder',
        message: 'Would you like to receive a reminder every hour to drink water? 💧',
        buttons: [
          { text: 'No', color: '#666666' },
          { text: 'Yes', color: '#007DFF' }
        ]
      }) as DialogResult

      vm.waterReminderActive = (data.index === 1)
      vm.selectedPlan = plan
      this.startFasting(vm, hours)
      await this.saveFastingData(vm)
      vm.currentPage = 'planDetail'
    } catch (e) {
      console.error('showDialog failed:', e)
    }
  }

  startFasting(vm: FastingVm, hours: number): void {
    vm.fastingStart = Date.now()
    vm.fastingEnd = vm.fastingStart + hours * 60 * 60 * 1000
    vm.remainingTime = this.formatRemaining(vm.fastingEnd - vm.fastingStart)
    vm.isFastingActive = false
    vm.notificationSent = false
    vm.waterIntake = 0
    vm.lastWaterReminder = Date.now()
    this.showRandomQuote(vm)
    clearInterval(this.timer)
  }

  runTimer(vm: FastingVm): void {
    if (vm.fastingEnd <= Date.now()) {
      const hours = this.getHoursFromPlan(vm.selectedPlan)
      this.startFasting(vm, hours)
    }

    vm.isFastingActive = true
    clearInterval(this.timer)

    this.updateRemaining(vm)
    this.timer = setInterval(() => {
      this.updateRemaining(vm)
      this.checkNotificationTime(vm)
      this.checkWaterReminder(vm)

      const rand = cryptoFramework.createRandom();
      if (rand.generateRandomSync(1).data[0] < 8) {
        this.showRandomQuote(vm)
      }
      vm.timerTrigger = !vm.timerTrigger
    }, 1000)
  }

  stopFasting(vm: FastingVm): void {
    vm.isFastingActive = false
    clearInterval(this.timer)
  }

  resetFasting(vm: FastingVm): void {
    vm.isFastingActive = false
    clearInterval(this.timer)
    vm.fastingStart = 0
    vm.fastingEnd = 0
    vm.remainingTime = ''
    // vm.selectedPlan = ''
    vm.notificationSent = false
    vm.waterReminderActive = false
    vm.waterIntake = 0
    vm.lastWaterReminder = 0
    vm.currentQuote = ''
  }

  updateRemaining(vm: FastingVm): void {
    const diff = vm.fastingEnd - Date.now()
    if (diff <= 0) {
      const hoursDone = (vm.fastingEnd - vm.fastingStart) / (1000 * 60 * 60)
      if (hoursDone > 0.1) {
        vm.totalFastCompleted += 1
        vm.totalHoursFasted += hoursDone
      }
      vm.remainingTime = '🎉 Congrats, fasting complete!'
      vm.isFastingActive = false
      clearInterval(this.timer)
      void this.saveFastingData(vm)
    } else {
      vm.remainingTime = this.formatRemaining(diff)
    }
  }

  checkNotificationTime(vm: FastingVm): void {
    if (!vm.isFastingActive || vm.notificationSent) {
      return;
    }
    const diff = vm.fastingEnd - Date.now()
    const oneHourInMs = 60 * 60 * 1000
    if (diff <= oneHourInMs && diff > 0) {
      void this.sendNotification(vm)
      vm.notificationSent = true
      void this.saveFastingData(vm)
    }
  }

  checkWaterReminder(vm: FastingVm): void {
    if (!vm.waterReminderActive || !vm.isFastingActive) {
      return;
    }
    const now = Date.now()
    const interval = 60 * 60 * 1000
    if (now - vm.lastWaterReminder >= interval) {
      void this.sendWaterReminder(vm)
      vm.lastWaterReminder = now
    }
  }

  showRandomQuote(vm: FastingVm): void {
    if (this.motivationalQuotes.length === 0) {
      return
    }
    const rand = cryptoFramework.createRandom();
    const b = rand.generateRandomSync(4).data;
    const u = (((b[0] << 24) | (b[1] << 16) | (b[2] << 8) | b[3]) >>> 0);
    const idx = u % this.motivationalQuotes.length;

    vm.currentQuote = this.motivationalQuotes[idx]
  }

  async sendNotification(vm: FastingVm): Promise<void> {
    try {
      const request: notificationManager.NotificationRequest = {
        id: NOTIFICATION_ID,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: 'Fasting Reminder',
            text: `Your fasting will end in 1 hour! 💪`,
            additionalText: vm.selectedPlan
          }
        },
        deliveryTime: Date.now()
      }
      await notificationManager.publish(request)
    } catch (error) {
      console.error('Notification Error:', error)
    }
  }

  async sendWaterReminder(vm: FastingVm): Promise<void> {
    try {
      const request: notificationManager.NotificationRequest = {
        id: NOTIFICATION_ID + 100,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: '💧 Water Reminder',
            text: 'Time to drink a glass of water!',
            additionalText: vm.selectedPlan
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

  async saveFastingData(vm: FastingVm): Promise<void> {
    try {
      const ctx = vm.getUIContext().getHostContext() as common.Context
      const pref = await preferences.getPreferences(ctx, PREF_NAME)

      await pref.put('fastingStart', vm.fastingStart)
      await pref.put('fastingEnd', vm.fastingEnd)
      await pref.put('isFastingActive', vm.isFastingActive)
      await pref.put('selectedPlan', vm.selectedPlan)
      await pref.put('notificationSent', vm.notificationSent)

      await pref.put('waterReminderActive', vm.waterReminderActive)
      await pref.put('lastWaterReminder', vm.lastWaterReminder)
      await pref.put('waterIntake', vm.waterIntake)
      await pref.put('dailyWaterGoal', vm.dailyWaterGoal)

      await pref.put('totalFastCompleted', vm.totalFastCompleted)
      await pref.put('totalHoursFasted', vm.totalHoursFasted)

      await pref.put('darkMode', vm.darkMode)

      await pref.flush()
    } catch (error) {
      console.error('Data Save Error:', error)
    }
  }

  async loadFastingData(vm: FastingVm): Promise<void> {
    try {
      const ctx = vm.getUIContext().getHostContext() as common.Context
      const pref = await preferences.getPreferences(ctx, PREF_NAME)

      vm.fastingStart = Number(await pref.get('fastingStart', 0))
      vm.fastingEnd = Number(await pref.get('fastingEnd', 0))
      vm.isFastingActive = (await pref.get('isFastingActive', false)) as boolean
      vm.selectedPlan = (await pref.get('selectedPlan', '')) as string
      vm.notificationSent = (await pref.get('notificationSent', false)) as boolean

      vm.waterReminderActive = (await pref.get('waterReminderActive', false)) as boolean
      vm.lastWaterReminder = Number(await pref.get('lastWaterReminder', 0))
      vm.waterIntake = Number(await pref.get('waterIntake', 0))
      vm.dailyWaterGoal = Number(await pref.get('dailyWaterGoal', 8))

      vm.totalFastCompleted = Number(await pref.get('totalFastCompleted', 0))
      vm.totalHoursFasted = Number(await pref.get('totalHoursFasted', 0))

      vm.darkMode = (await pref.get('darkMode', true)) as boolean

      if (vm.fastingEnd > 0) {
        if (vm.fastingEnd > Date.now()) {
          this.updateRemaining(vm)
          if (vm.isFastingActive) {
            this.runTimer(vm)
          }
        } else if (vm.isFastingActive) {
          const hoursDone = (vm.fastingEnd - vm.fastingStart) / (1000 * 60 * 60)
          if (hoursDone > 0.1) {
            vm.totalFastCompleted += 1
            vm.totalHoursFasted += hoursDone
          }
          vm.remainingTime = '🎉 Congrats, fasting complete!'
          vm.isFastingActive = false
          vm.notificationSent = false
          await this.saveFastingData(vm)
        } else {
          vm.remainingTime = 'Completed'
        }
      }

      this.showRandomQuote(vm)
    } catch (error) {
      console.error('Data Load Error:', error)
    }
  }
}
