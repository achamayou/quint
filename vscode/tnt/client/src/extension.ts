/* ----------------------------------------------------------------------------------
 * Copyright (c) Informal Systems. All rights reserved.
 * Licensed under the Apache 2.0.
 * See License.txt in the project root for license information.
 * --------------------------------------------------------------------------------- */

import * as path from 'path'
import { cwd } from 'process'
import { workspace, ExtensionContext, commands, Uri, window } from 'vscode'

import {
  LanguageClient,
  LanguageClientOptions,
  ServerOptions,
  TransportKind
} from 'vscode-languageclient/node'

let client: LanguageClient

export function activate (context: ExtensionContext) {
  // The server is implemented in node
  const serverModule = context.asAbsolutePath(
    path.join('server', 'out', 'server.js')
  )

  const command = 'tnt.getExampleForAction';

  const commandHandler = async (name: string = 'Next') => {
    // const activeEditor = window.activeTextEditor;
    // if (!activeEditor) {
    //   return;
    // }
    //   activeEditor.document.,
    let uri = Uri.file('/home/gabriela/projects/tnt/examples/tictactoe/example.itf.json');
    let success = await commands.executeCommand('vscode.openFolder', uri);
  };

  context.subscriptions.push(commands.registerCommand(command, commandHandler));

  // The debug options for the server
  // --inspect=6009: runs the server in Node's Inspector mode
  // so VS Code can attach to the server for debugging
  const debugOptions = { execArgv: ['--nolazy', '--inspect=6009'] }

  // If the extension is launched in debug mode then the debug server options are used
  // Otherwise the run options are used
  const serverOptions: ServerOptions = {
    run: { module: serverModule, transport: TransportKind.ipc },
    debug: {
      module: serverModule,
      transport: TransportKind.ipc,
      options: debugOptions,
    },
  }

  // Options to control the language client
  const clientOptions: LanguageClientOptions = {
    // Register the server for plain text documents
    documentSelector: [{ scheme: 'file', language: 'tnt' }],
    synchronize: {
      // watch for changes in TNT files
      fileEvents: workspace.createFileSystemWatcher('**/*.tnt'),
    },
  }

  // Create the language client and start the client.
  client = new LanguageClient(
    'tntLspClient',
    'LSP for TNT',
    serverOptions,
    clientOptions
  )

  // Start the client. This will also launch the server
  client.start()
}

export function deactivate (): Promise<void> | undefined {
  if (!client) {
    return undefined
  }
  return client.stop()
}
