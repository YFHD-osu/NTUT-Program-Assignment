function Get-Depth {
            param ( $path )

            $items = Get-ChildItem -Path $path -Directory

            if ($items.Length -eq 0) {
              return $path
            } else {
              return Get-Depth($items[0])
            }
          }

          $releaseFolder = Get-Depth(".\dist")
          $releaseFolder = $releaseFolder.FullName.replace("\", "/")

Write-Host $releaseFolder