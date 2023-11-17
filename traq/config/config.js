;(() => {
  const config = {
    name: 'traQ',
    firebase: {
      apiKey: 'AIzaSyBEuFTohGT_FZkB-FQXmMA-1NSWtjBdLc0',
      appId: '1:905974313870:web:a9010642076016fe08aadf',
      projectId: 'hobby-256508',
      messagingSenderId: '905974313870'
    },
    skyway: {
      apiKey: '5f4f8911-12b4-4055-83c1-29a958d21ba6'
    },
    enableSearch: true,
    services: [
      {
        label: 'Bot Console',
        iconPath: 'bot-console.svg',
        appLink: 'https://bot-console.toki317.dev'
      },
      {
        label: 'NeoShowcase',
        iconPath: 'neoshowcase.svg',
        appLink: 'https://ns.toki317.dev'
      }
    ],
    ogpIgnoreHostNames: [
      'bot-console.toki317.dev',
      'ns.toki317.dev'
    ],
//    wikiPageOrigin: 'https://wiki.example.com',
    isRootChannelSelectableAsParentChannel: true,
    tooLargeFileMessage: '大きい%sの共有にはGoogleDriveを使用してください',
    showWidgetCopyButton: true,
    inlineReplyDisableChannels: ['#general']
  }

  self.traQConfig = config
})()
