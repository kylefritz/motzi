# Marketing assets — original → S3 map

Generated from `rake marketing:fetch_assets` on 2026-05-12. Use the right column when
referencing images in `app/views/{home,about,subscribe,contact}/show.html.erb`.

All assets live under `s3://motzi/public/marketing/` which is publicly readable via the
bucket policy (no per-object ACLs needed).

| Name | Original (Wix CDN) | S3 |
|---|---|---|
| `Motzi_logo_web_edited_edited.png` | `https://static.wixstatic.com/media/0e6926_461ca570e24f4af18aff571baa07cea2~mv2.png` | `https://motzi.s3.us-east-1.amazonaws.com/public/marketing/Motzi_logo_web_edited_edited.png` |
| `instagram_icon.png` | `https://static.wixstatic.com/media/40898a93cfff4578b1779073137eb1b4.png` | `https://motzi.s3.us-east-1.amazonaws.com/public/marketing/instagram_icon.png` |
| `Kate_drawing_hero.jpg` | `https://static.wixstatic.com/media/0e6926_2bd61b90080c4d7f895840a4ab150e5e~mv2.jpg` | `https://motzi.s3.us-east-1.amazonaws.com/public/marketing/Kate_drawing_hero.jpg` |
| `NM_20200702_11_41_38-2_websize.jpg` | `https://static.wixstatic.com/media/0e6926_d691f726677c4cc494d88c9d2537c1b5~mv2.jpg` | `https://motzi.s3.us-east-1.amazonaws.com/public/marketing/NM_20200702_11_41_38-2_websize.jpg` |
| `NM_20200702_12_48_55_websize.jpg` | `https://static.wixstatic.com/media/0e6926_ececf75ee6654d0ba81ad8c1f15f45f1~mv2.jpg` | `https://motzi.s3.us-east-1.amazonaws.com/public/marketing/NM_20200702_12_48_55_websize.jpg` |
| `nsplsh_685133575a6e5933795a30_mv2_d_5906_3937_s_4_2.jpg` | `https://static.wixstatic.com/media/nsplsh_685133575a6e5933795a30~mv2_d_5906_3937_s_4_2.jpg` | `https://motzi.s3.us-east-1.amazonaws.com/public/marketing/nsplsh_685133575a6e5933795a30_mv2_d_5906_3937_s_4_2.jpg` |
| `NM_20200723_14_12_12_websize_edited.jpg` | `https://static.wixstatic.com/media/0e6926_01f6d2dd66064697bac0356b585c9d7c~mv2.jpg` | `https://motzi.s3.us-east-1.amazonaws.com/public/marketing/NM_20200723_14_12_12_websize_edited.jpg` |
| `harvesting-hulless-oats.jpg` | `https://static.wixstatic.com/media/0e6926_1311a5b3a98046e89ac6c75f1fdbf9fc~mv2.jpg` | `https://motzi.s3.us-east-1.amazonaws.com/public/marketing/harvesting-hulless-oats.jpg` |
| `NM_20200702_12_58_37_websize.jpg` | `https://static.wixstatic.com/media/0e6926_1de8dfb61580466085fe1a216c5d656a~mv2.jpg` | `https://motzi.s3.us-east-1.amazonaws.com/public/marketing/NM_20200702_12_58_37_websize.jpg` |
| `NM_20200702_12_11_36_websize.jpg` | `https://static.wixstatic.com/media/0e6926_e97ddc3e63db4331946b5d84e1d8e392~mv2.jpg` | `https://motzi.s3.us-east-1.amazonaws.com/public/marketing/NM_20200702_12_11_36_websize.jpg` |

## Page usage

| Page | Asset(s) |
|---|---|
| Shared (nav / footer) | `Motzi_logo_web_edited_edited.png`, `instagram_icon.png` |
| Home | `Kate_drawing_hero.jpg`, `NM_20200702_11_41_38-2_websize.jpg`, `NM_20200702_12_48_55_websize.jpg` |
| About | `nsplsh_...jpg` (hero), `NM_20200723_14_12_12_websize_edited.jpg`, `harvesting-hulless-oats.jpg`, `NM_20200702_12_58_37_websize.jpg`, `NM_20200702_12_11_36_websize.jpg` |
