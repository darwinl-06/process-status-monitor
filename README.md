# Data Center Monitoring Tools

This project consists of the development of two tools (one in PowerShell and one in Bash) designed to assist data center administrators who manage both Windows and Linux machines. These tools help in monitoring and managing the processes running on the servers. The tools are as follows:

## Team members

- Dylan Bermúdez Cardona
- Darwin Lenis Maturana
- Juan Felipe Madrid

## Tools Overview

### 1. Windows Server Process Monitoring Tool

This tool is a PowerShell script that monitors the processes running on a Windows server. It provides a web interface with the following features:

- Display an HTML table of the current processes running on the machine.
- Allow users to terminate a process by selecting it from a list. The process is terminated with a simple button click for ease of use.

### 2. Linux Server Process Monitoring Tool

This tool is a Bash script that monitors the processes running on a Linux server. Similar to the Windows tool, it provides a web interface with the following features:

- Display an HTML table of the current processes running on the machine.
- Allow users to terminate a process by selecting it from a list, without the need to manually input the process ID.

## Features

- **Web-based Interface**: Both tools provide a simple web interface that can be accessed via any modern web browser.
- **Automatic Process Updates**: The process tables are updated every 2 seconds to reflect the latest system status.
- **Process Termination**: Users can terminate any process by selecting it from a table, making it user-friendly and avoiding errors from manually typing process IDs.

## Installation and Usage

### Requirements

- **Windows Server Tool**: Requires PowerShell (compatible with Windows 10 and later).
- **Linux Server Tool**: Requires a Linux-based server with Bash and a web server to serve the HTML content (e.g., Apache or Nginx).
