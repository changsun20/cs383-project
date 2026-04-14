export default {
  title: 'ArtDAO Documentation',
  description: 'Documentation for ArtCommission and ArtDAO smart contracts',
  base: '/cs383-project/',
  
  themeConfig: {
    nav: [
      { text: 'Home', link: '/' },
      { text: 'ArtCommission', link: '/art-commission/overview' },
      { text: 'ArtDAO', link: '/art-dao/overview' }
    ],
    
    sidebar: [
      {
        text: 'Introduction',
        link: '/'
      },
      {
        text: 'ArtCommission Contract',
        collapsible: true,
        items: [
          { text: 'Overview', link: '/art-commission/overview' },
          { text: 'State Variables', link: '/art-commission/state-variables' },
          { text: 'Functions', link: '/art-commission/functions' },
          { text: 'Known Bugs', link: '/art-commission/known-bugs' }
        ]
      },
      {
        text: 'ArtDAO Contract',
        collapsible: true,
        items: [
          { text: 'Overview', link: '/art-dao/overview' },
          { text: 'Invariants', link: '/art-dao/invariants' },
          { text: 'State Variables', link: '/art-dao/state-variables' },
          { text: 'Functions', link: '/art-dao/functions' },
          { text: 'Events', link: '/art-dao/events' },
          { text: 'Known Bugs', link: '/art-dao/known-bugs' }
        ]
      }
    ],
    
    socialLinks: [
      { icon: 'github', link: 'https://github.com/changsun20/cs383-project' }
    ],
    
    footer: {
      message: 'Released under the MIT License.',
      copyright: 'Copyright © 2025 ArtDAO Project'
    }
  }
}