'use client'

import { wagmiAdapter, projectId } from '@/config'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { createAppKit } from '@reown/appkit/react'
import { mainnet, arbitrum, baseSepolia, base } from '@reown/appkit/networks'
import React, { type ReactNode } from 'react'
import { cookieToInitialState, WagmiProvider, type Config } from 'wagmi'

const queryClient = new QueryClient()

if (!projectId) {
  throw new Error('Project ID is not defined')
}

const metadata = {
  name: 'appkit-example',
  description: 'AppKit Example',
  url: 'https://appkitexampleapp.com', 
  icons: ['https://avatars.githubusercontent.com/u/179229932']
}

const modal = createAppKit({
  adapters: [wagmiAdapter],
  projectId,
  networks: [baseSepolia, base],
  defaultNetwork: baseSepolia,
  metadata: metadata,
  features: {
    analytics: true 
  }
})

function ContextProvider({ children, cookies }: { children: ReactNode; cookies: string | null }) {
  const initialState = cookieToInitialState(wagmiAdapter.wagmiConfig as Config, cookies)

  return (
    <WagmiProvider config={wagmiAdapter.wagmiConfig as Config} initialState={initialState}>
      <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
    </WagmiProvider>
  )
}

export default ContextProvider