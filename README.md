# Octos

## Setup

To run this project, you will need:
- [asdf](https://asdf-vm.com/)
- [docker compose](https://docs.docker.com/compose/)

Add Elixir and Erlang plugins to asdf and install them:
```sh
asdf plugin add erlang
asdf plugin add elixir

# Install versions specified in the .tool-versions file
asdf install
```

Set up the project
```sh
# Start postgres
docker compose up -d

mix deps.get
mix ecto.setup
```

Now you are ready to start the server:
```sh
mix phx.server
```

## Routes overview

### 1. **GET `/cameras`**
#### Query Parameters

| Parameter     | Type    | Description                             | Constraints                      | Default   |
|---------------|---------|-----------------------------------------|----------------------------------|-----------|
| `name`        | String  | Filter cameras by name                  |                                  | `nil`     |
| `sort`        | Enum    | Field to sort by                        | Values: `["name"]`               | `"name"`  |
| `direction`   | Enum    | Sort direction                          | Values: `["asc", "desc"]`        | `"asc"`   |
| `page`        | Integer | Page number for pagination              | Min: `1`                         | `1`       |
| `page_size`   | Integer | Number of users per page                | Min: `1`, Max: `100`             | `50`      |

#### Response

```json
{
  "users": [
    {
      "id": 1001,
      "name": "Daisy Jacobi",
      "cameras": [
        {
          "active": true,
          "id": 33,
          "name": "Annihilus",
          "brand": "Intelbras"
        },
        {
          "active": true,
          "id": 35,
          "name": "Walrus",
          "brand": "Vivotek"
        }
      ],
      "email": "dena.ratke@mcglynn.name",
      "inactivation_date": null
    },
    {
      "id": 1002,
      "name": "Ubaldo Mosciski",
      "cameras": [
        {
          "active": true,
          "id": 95,
          "name": "Aqualad",
          "brand": "Intelbras"
        }
      ],
      "email": "emerald2051@schmidt.net",
      "inactivation_date": "2025-01-11T04:21:41Z"
    }
  ],
  "page": 1,
  "total_pages": 10
}
```

---

### 2. **POST `/notify-users`**

#### Request Body (optional)
The endpoint accepts a JSON payload specifying the brand of the camera:

```json
{
  "brand": "Giga"
}
```

#### Response

No content

## Implementation details

- I thought it would be better to run the seed only in the dev environment.
Running it in the test environment would make it harder to test the records being seeded.
Since it currently runs only in the dev environment, it would make more sense for it to be a Mix task.
- I ended up using two libraries that validate parameters (Goal and Flop). The reason for this is that
I find the format used by Flop a bit awkward to expose directly through the API. Additionally,
I didn’t want to be tied to the format of a specific library, considering it might be replaced in the future.
As a result, Goal is used to validate the parameters, while Flop handles filtering and sorting. 
