# NetApp Volume and LUN Datastore Script

This repository contains a PowerShell script for creating and managing NetApp volumes and LUNs for datastores.

## Prerequisites

- PowerShell
- NetApp PowerShell Toolkit
- Access to the NetApp cluster

## Usage

1. Clone the repository:
    ```sh
    git clone https://github.com/schmidsebas/NetApp-Vol-Lun-Datastore.git
    ```

2. Navigate to the script directory:
    ```sh
    cd NetApp-Vol-Lun-Datastore/public/Netapp
    ```

3. Open the script file `NetApp-Vol-Lun-Datastorel.ps1` and modify the following variables as needed:
    ```powershell
    $datastoreName = "TEST-06"
    $volLunSize = 1
    $NACL = "192.168.178.131"
    $Nuser = "admin"
    $Npw = "Netapp1!"
    ```

4. Run the script:
    ```powershell
    .\NetApp-Vol-Lun-Datastorel.ps1
    ```

## Script Details

The script performs the following actions:
- Connects to the NetApp cluster using the provided credentials.
- Determines the appropriate SVM and aggregate based on the datastore name.
- Creates a new volume with specified options.
- Configures volume options such as fractional reserve, read realloc, and no atime update.
- Enables volume autosize with a specified maximum size and increment size.
- Creates a new LUN within the volume.
- Maps the LUN to an initiator group.

## License

This project is licensed under the MIT License.